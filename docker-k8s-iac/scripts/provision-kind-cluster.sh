set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

if [ ! -f .env ] && [ -f .env.example ]; then
  cp .env.example .env
fi

set -a
source .env
set +a

require_command() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "Missing required command: $1" >&2
    exit 1
  fi
}

require_command ssh
require_command scp
require_command kubectl

SSH_CONTEXT_HOST="${DOCKER_CONTEXT_HOST:-${DOCKER_CONTEXT:-}}"
SSH_CONTEXT_USER="${DOCKER_CONTEXT_USER:-}"
KUBE_CONTEXT="${KUBE_CONTEXT:?Set KUBE_CONTEXT in .env or environment}"
KIND_CLUSTER_NAME="${KIND_CLUSTER_NAME:-blitzinfra}"
KIND_WORKER_COUNT="${KIND_WORKER_COUNT:-4}"
KIND_API_SERVER_PORT="${KIND_API_SERVER_PORT:-6443}"
KIND_WAIT_DURATION="${KIND_WAIT_DURATION:-300s}"
KIND_API_SERVER_HOST="${KIND_API_SERVER_HOST:-$SSH_CONTEXT_HOST}"

if [ -z "$SSH_CONTEXT_HOST" ] || [ -z "$SSH_CONTEXT_USER" ]; then
  echo "Set DOCKER_CONTEXT_HOST and DOCKER_CONTEXT_USER in .env before provisioning kind." >&2
  exit 1
fi

SSH_TARGET="${SSH_CONTEXT_USER}@${SSH_CONTEXT_HOST}"

if ! ssh -o BatchMode=yes -o ConnectTimeout=10 "$SSH_TARGET" true >/dev/null 2>&1; then
  echo "SSH access is not ready for ${SSH_TARGET}" >&2
  echo "Running SSH setup prerequisite..." >&2
  ./scripts/setup-ssh-access.sh
fi

ssh "$SSH_TARGET" "command -v docker >/dev/null 2>&1 && command -v kind >/dev/null 2>&1" || {
  echo "Remote host ${SSH_TARGET} must have both docker and kind installed." >&2
  exit 1
}

TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT
LOCAL_KIND_CONFIG="${TMP_DIR}/kind-cluster.yaml"
REMOTE_KIND_CONFIG="/tmp/${KIND_CLUSTER_NAME}-kind-config.yaml"
REMOTE_KUBECONFIG="\$HOME/.kube/${KIND_CLUSTER_NAME}.config"
LOCAL_REMOTE_KUBECONFIG="${TMP_DIR}/remote-kubeconfig.yaml"
LOCAL_IMPORT_KUBECONFIG="${TMP_DIR}/import-kubeconfig.yaml"
LOCAL_MERGED_KUBECONFIG="${TMP_DIR}/merged-kubeconfig.yaml"

{
  printf '%s\n' 'kind: Cluster'
  printf '%s\n' 'apiVersion: kind.x-k8s.io/v1alpha4'
  printf '%s\n' 'networking:'
  printf '%s\n' '  apiServerAddress: "0.0.0.0"'
  printf '  apiServerPort: %s\n' "$KIND_API_SERVER_PORT"
  printf '%s\n' 'nodes:'
  printf '%s\n' '- role: control-plane'
  worker_index=1
  while [ "$worker_index" -le "$KIND_WORKER_COUNT" ]; do
    printf '%s\n' '- role: worker'
    worker_index=$((worker_index + 1))
  done
} > "$LOCAL_KIND_CONFIG"

scp "$LOCAL_KIND_CONFIG" "${SSH_TARGET}:${REMOTE_KIND_CONFIG}"

ssh "$SSH_TARGET" "
  set -euo pipefail
  mkdir -p \"\$HOME/.kube\"
  if kind get clusters | grep -Fx '${KIND_CLUSTER_NAME}' >/dev/null 2>&1; then
    kind export kubeconfig --name '${KIND_CLUSTER_NAME}' --kubeconfig ${REMOTE_KUBECONFIG}
  else
    kind create cluster --name '${KIND_CLUSTER_NAME}' --config '${REMOTE_KIND_CONFIG}' --wait '${KIND_WAIT_DURATION}' --kubeconfig ${REMOTE_KUBECONFIG}
  fi
"

scp "${SSH_TARGET}:~/.kube/${KIND_CLUSTER_NAME}.config" "$LOCAL_REMOTE_KUBECONFIG"

sed "s#server: https://.*#server: https://${KIND_API_SERVER_HOST}:${KIND_API_SERVER_PORT}#" "$LOCAL_REMOTE_KUBECONFIG" > "$LOCAL_IMPORT_KUBECONFIG"

mkdir -p "$HOME/.kube"
if [ -f "$HOME/.kube/config" ]; then
  KUBECONFIG="$HOME/.kube/config:$LOCAL_IMPORT_KUBECONFIG" kubectl config view --flatten > "$LOCAL_MERGED_KUBECONFIG"
else
  cp "$LOCAL_IMPORT_KUBECONFIG" "$LOCAL_MERGED_KUBECONFIG"
fi

REMOTE_CURRENT_CONTEXT="$(kubectl --kubeconfig "$LOCAL_IMPORT_KUBECONFIG" config current-context)"
if [ -n "$REMOTE_CURRENT_CONTEXT" ] && [ "$REMOTE_CURRENT_CONTEXT" != "$KUBE_CONTEXT" ]; then
  kubectl --kubeconfig "$LOCAL_MERGED_KUBECONFIG" config delete-context "$KUBE_CONTEXT" >/dev/null 2>&1 || true
  kubectl --kubeconfig "$LOCAL_MERGED_KUBECONFIG" config rename-context "$REMOTE_CURRENT_CONTEXT" "$KUBE_CONTEXT"
fi

if [ -n "${KUBE_NAMESPACE:-}" ]; then
  kubectl --kubeconfig "$LOCAL_MERGED_KUBECONFIG" config set-context "$KUBE_CONTEXT" --namespace="$KUBE_NAMESPACE" >/dev/null
fi

cp "$LOCAL_MERGED_KUBECONFIG" "$HOME/.kube/config"

echo "kind cluster ${KIND_CLUSTER_NAME} is ready on ${SSH_CONTEXT_HOST} with context ${KUBE_CONTEXT}"
