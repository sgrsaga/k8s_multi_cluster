#!/usr/bin/env bash
set -euo pipefail

# Usage: ./scripts/render-inventory.sh [provider] <cluster> [--init]
#
# Reads terraform output for the given cluster and rewrites the [all] block
# in clusters/<cluster>/inventory.ini with real node IPs:
#   ansible_host = public IP  (SSH reachability for kubespray)
#   ip           = private IP (NIC-bound address kubelet/etcd bind to;
#                              falls back to public IP when the provider
#                              has no separate private NIC, e.g. bare metal)
# Bare-metal joiner lines (commented) are preserved untouched.
#
#   ./scripts/render-inventory.sh aws dev-ap-south-1
#   ./scripts/render-inventory.sh gcp dev-asia-south1 --init
#   ./scripts/render-inventory.sh dev-ap-south-1            # provider defaults to aws

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

ARG1="${1:?Usage: ./scripts/render-inventory.sh [provider] <cluster> [--init]}"

if [[ -d "${REPO_ROOT}/terraform/${ARG1}" ]]; then
  PROVIDER="${ARG1}"
  shift
else
  PROVIDER="aws"
fi

CLUSTER="${1:?Usage: ./scripts/render-inventory.sh [provider] <cluster> [--init]}"
INIT=false
[[ "${2:-}" == "--init" ]] && INIT=true

TF_DIR="${REPO_ROOT}/terraform/${PROVIDER}"
CLUSTER_DIR="${REPO_ROOT}/clusters/${CLUSTER}"
INVENTORY="${CLUSTER_DIR}/inventory.ini"

for cmd in terraform jq; do
  command -v "$cmd" &>/dev/null || { echo "Error: $cmd not found in PATH" >&2; exit 1; }
done

if [[ ! -f "${TF_DIR}/${CLUSTER}.tfvars" ]]; then
  echo "Error: ${TF_DIR}/${CLUSTER}.tfvars not found" >&2
  exit 1
fi

if [[ ! -f "${INVENTORY}" ]]; then
  echo "Error: inventory not found: ${INVENTORY}" >&2
  echo "Hint: scaffold it with ./scripts/new-cluster.sh ${PROVIDER} ${CLUSTER}" >&2
  exit 1
fi

if [[ "${INIT}" == true ]]; then
  echo "Re-initialising Terraform backend for ${PROVIDER}/${CLUSTER}..."
  (cd "${TF_DIR}" && terraform init \
    -backend-config="backends/${CLUSTER}.hcl" \
    -reconfigure -no-color)
fi

echo "Reading Terraform outputs for ${PROVIDER}/${CLUSTER}..."
TF_OUTPUT=$(cd "${TF_DIR}" && terraform output -json)

mapfile -t PUBLIC_IPS < <(echo "${TF_OUTPUT}" | jq -r '.node_public_ips.value[]? // empty')
mapfile -t PRIVATE_IPS < <(echo "${TF_OUTPUT}" | jq -r '.node_private_ips.value[]? // empty')

if [[ ${#PUBLIC_IPS[@]} -eq 0 ]]; then
  echo "Error: no node_public_ips in Terraform output. Has terraform apply been run" \
       "with the ${CLUSTER} backend initialised (try --init)?" >&2
  exit 1
fi

# Fall back to public IPs when the provider has no separate private NIC.
if [[ ${#PRIVATE_IPS[@]} -ne ${#PUBLIC_IPS[@]} ]]; then
  PRIVATE_IPS=("${PUBLIC_IPS[@]}")
fi

echo "Found ${#PUBLIC_IPS[@]} node(s): ${PUBLIC_IPS[*]}"

# Build replacement [all] block (terraform nodes only; bare-metal joiner lines preserved by awk).
ALL_BLOCK="[all]"$'\n'
for i in "${!PUBLIC_IPS[@]}"; do
  N=$((i + 1))
  ALL_BLOCK+="node-${N} ansible_host=${PUBLIC_IPS[$i]} ip=${PRIVATE_IPS[$i]} etcd_member_name=etcd${N}"$'\n'
done

TMPFILE=$(mktemp)
trap 'rm -f "${TMPFILE}"' EXIT

# awk rewrites the [all] block:
#   - Replaces "node-N ansible_host=..." lines with fresh IPs.
#   - Preserves commented bare-metal lines verbatim.
#   - Leaves all other sections untouched.
awk -v new_block="${ALL_BLOCK}" '
  /^\[all\]/ {
    print new_block
    in_all = 1
    next
  }
  in_all && /^\[/ {
    in_all = 0
  }
  in_all && /^node-[0-9]+ ansible_host=/ {
    next
  }
  { print }
' "${INVENTORY}" > "${TMPFILE}"

mv "${TMPFILE}" "${INVENTORY}"
echo "Inventory updated: ${INVENTORY}"
echo
echo "Next: ./scripts/kubespray.sh ${CLUSTER} cluster.yml"
