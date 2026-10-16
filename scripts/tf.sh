#!/usr/bin/env bash
set -euo pipefail

# Usage: ./scripts/tf.sh [provider] <cluster> <terraform-command> [extra-terraform-flags]
#
#   ./scripts/tf.sh aws dev-ap-south-1 plan
#   ./scripts/tf.sh gcp dev-asia-south1 apply
#   ./scripts/tf.sh digitalocean dev-blr1 apply
#   ./scripts/tf.sh latitude dev-sao destroy
#   ./scripts/tf.sh aws dev-ap-southeast-1 apply -target=module.network
#
# Backward compatible: if the first argument is not a provider directory under
# terraform/, it is treated as a cluster name and the provider defaults to aws:
#   ./scripts/tf.sh dev-ap-south-1 plan        # == ./scripts/tf.sh aws dev-ap-south-1 plan
#
# Each cluster has its own state key (terraform/<provider>/backends/<cluster>.hcl).
# This script re-inits with the correct backend before every command so that
# running two clusters from the same directory never shares state.

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

ARG1="${1:?Usage: ./scripts/tf.sh [provider] <cluster> <command> [flags]}"

if [[ -d "${REPO_ROOT}/terraform/${ARG1}" ]]; then
  PROVIDER="${ARG1}"
  shift
else
  PROVIDER="aws"
fi

CLUSTER="${1:?Usage: ./scripts/tf.sh [provider] <cluster> <command> [flags]}"
COMMAND="${2:?Usage: ./scripts/tf.sh [provider] <cluster> <command> [flags]}"
shift 2

TF_DIR="${REPO_ROOT}/terraform/${PROVIDER}"
BACKEND_CFG="${TF_DIR}/backends/${CLUSTER}.hcl"
TFVARS="${TF_DIR}/${CLUSTER}.tfvars"

if [[ ! -f "${BACKEND_CFG}" ]]; then
  echo "Error: backend config not found: ${BACKEND_CFG}" >&2
  exit 1
fi

if [[ ! -f "${TFVARS}" ]]; then
  echo "Error: tfvars file not found: ${TFVARS}" >&2
  exit 1
fi

cd "${TF_DIR}"

echo "==> terraform init -reconfigure (provider: ${PROVIDER}, backend: ${CLUSTER})"
terraform init -reconfigure -backend-config="${BACKEND_CFG}"

# Subcommands that do not accept -var/-var-file.
case "${COMMAND}" in
  output|show|state|providers|fmt|version)
    echo "==> terraform ${COMMAND} (cluster: ${CLUSTER})"
    exec terraform "${COMMAND}" "$@"
    ;;
esac

echo "==> terraform ${COMMAND} (cluster: ${CLUSTER})"
terraform "${COMMAND}" \
  -var-file="${TFVARS}" \
  -var="cluster_name=${CLUSTER}" \
  "$@"
