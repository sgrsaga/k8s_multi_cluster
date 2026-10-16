#!/usr/bin/env bash
set -euo pipefail

# Usage: ./scripts/new-cluster.sh <provider> <cluster> <environment> <region> [--managed] [--server <url>]
#
# Scaffolds everything a new cluster needs besides terraform tfvars/backend files:
#
#   1. clusters/<cluster>/           kubespray inventory + group_vars  (skipped with --managed)
#   2. gitops/clusters/<cluster>/    ArgoCD ApplicationSet registration (cluster.yaml + values/)
#
#   ./scripts/new-cluster.sh aws prod-eu-west-1 prod eu-west-1
#   ./scripts/new-cluster.sh gcp dev-gke-asia-south1 dev asia-south1 --managed
#   ./scripts/new-cluster.sh ovh dev-ovh-eu dev eu-bhs
#
# --managed  : managed k8s (EKS/GKE/DOKS) — no kubespray inventory is created.
# --server   : ArgoCD destination server URL for cluster.yaml. Defaults to
#              PENDING_ARGOCD_REGISTRATION; replace it after `argocd cluster add`
#              with the server URL shown by `argocd cluster list`.
#
# After scaffolding:
#   - kubespray mode: create terraform/<provider>/{<cluster>.tfvars,backends/<cluster>.hcl},
#     apply, then ./scripts/render-inventory.sh <provider> <cluster> and
#     ./scripts/kubespray.sh <cluster> cluster.yml
#   - register with ArgoCD: argocd cluster add <context> --name <cluster>, set the
#     server URL in gitops/clusters/<cluster>/cluster.yaml, commit and push — the
#     base-addons ApplicationSet picks the cluster up automatically.

PROVIDER="${1:?Usage: ./scripts/new-cluster.sh <provider> <cluster> <environment> <region> [--managed] [--server <url>]}"
CLUSTER="${2:?Usage: ./scripts/new-cluster.sh <provider> <cluster> <environment> <region> [--managed] [--server <url>]}"
ENVIRONMENT="${3:?Usage: ./scripts/new-cluster.sh <provider> <cluster> <environment> <region> [--managed] [--server <url>]}"
REGION="${4:?Usage: ./scripts/new-cluster.sh <provider> <cluster> <environment> <region> [--managed] [--server <url>]}"
shift 4

MANAGED=false
SERVER="PENDING_ARGOCD_REGISTRATION"
while [[ $# -gt 0 ]]; do
  case "$1" in
    --managed) MANAGED=true; shift ;;
    --server)  SERVER="${2:?--server requires a URL}"; shift 2 ;;
    *) echo "Error: unknown flag $1" >&2; exit 1 ;;
  esac
done

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

if [[ ! -d "${REPO_ROOT}/terraform/${PROVIDER}" ]]; then
  echo "Error: unknown provider '${PROVIDER}' (no terraform/${PROVIDER}/ directory)" >&2
  exit 1
fi

# --- 1. kubespray cluster directory -----------------------------------------
if [[ "${MANAGED}" == false ]]; then
  CLUSTER_DIR="${REPO_ROOT}/clusters/${CLUSTER}"
  if [[ -e "${CLUSTER_DIR}" ]]; then
    echo "Skip: ${CLUSTER_DIR} already exists"
  else
    cp -r "${REPO_ROOT}/clusters/_template" "${CLUSTER_DIR}"
    grep -rl '__CLUSTER_NAME__' "${CLUSTER_DIR}" | while read -r f; do
      sed -i "s/__CLUSTER_NAME__/${CLUSTER}/g" "$f"
    done
    echo "Created ${CLUSTER_DIR} (review group_vars — ansible_user, CIDRs — before running kubespray)"
  fi
fi

# --- 2. gitops cluster registration ------------------------------------------
GITOPS_DIR="${REPO_ROOT}/gitops/clusters/${CLUSTER}"
TEMPLATE_VALUES="${REPO_ROOT}/gitops/clusters/dev-ap-south-1/values"
if [[ -e "${GITOPS_DIR}" ]]; then
  echo "Skip: ${GITOPS_DIR} already exists"
else
  mkdir -p "${GITOPS_DIR}"
  cp -r "${TEMPLATE_VALUES}" "${GITOPS_DIR}/values"
  cat > "${GITOPS_DIR}/cluster.yaml" <<EOF
# Cluster registration for the base-addons ApplicationSet.
# 'name' must match the ArgoCD cluster name (argocd cluster add <ctx> --name ${CLUSTER}).
# 'server' must match the ArgoCD cluster server URL (argocd cluster list).
# For the management cluster itself use https://kubernetes.default.svc.
name: ${CLUSTER}
server: ${SERVER}
environment: ${ENVIRONMENT}
region: ${REGION}
provider: ${PROVIDER}
# kubespray = we install the CNI (cilium addon deployed)
# managed   = EKS/GKE/DOKS provide the CNI (cilium addon skipped)
clusterType: $([[ "${MANAGED}" == true ]] && echo managed || echo kubespray)
EOF
  echo "Created ${GITOPS_DIR} (edit values/*.yaml for this cluster, set server URL after ArgoCD registration)"
fi

echo
echo "Next steps:"
echo "  1. Create terraform/${PROVIDER}/${CLUSTER}.tfvars and terraform/${PROVIDER}/backends/${CLUSTER}.hcl"
echo "  2. ./scripts/tf.sh ${PROVIDER} ${CLUSTER} apply"
if [[ "${MANAGED}" == false ]]; then
  echo "  3. ./scripts/render-inventory.sh ${PROVIDER} ${CLUSTER}"
  echo "  4. ./scripts/kubespray.sh ${CLUSTER} cluster.yml"
  echo "  5. argocd cluster add <kube-context> --name ${CLUSTER}; update server: in ${GITOPS_DIR#"${REPO_ROOT}"/}/cluster.yaml; git push"
else
  echo "  3. Get kubeconfig (see terraform output kubeconfig_command)"
  echo "  4. argocd cluster add <kube-context> --name ${CLUSTER}; update server: in ${GITOPS_DIR#"${REPO_ROOT}"/}/cluster.yaml; git push"
fi
