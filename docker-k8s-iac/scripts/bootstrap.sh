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

require_command curl
require_command docker
require_command kubectl
require_command ssh
./scripts/docker-compose-command.sh >/dev/null

DOCKER_CONTEXT="${DOCKER_CONTEXT:?Set DOCKER_CONTEXT in .env or environment}"
SSH_CONTEXT_HOST="${DOCKER_CONTEXT_HOST:-$DOCKER_CONTEXT}"
SSH_CONTEXT_USER="${DOCKER_CONTEXT_USER:-}"

if [ -n "$SSH_CONTEXT_USER" ] && ! ssh -o BatchMode=yes -o ConnectTimeout=10 "${SSH_CONTEXT_USER}@${SSH_CONTEXT_HOST}" true >/dev/null 2>&1; then
  echo "SSH access is not ready for ${SSH_CONTEXT_USER}@${SSH_CONTEXT_HOST}" >&2
  echo "Running SSH setup prerequisite..." >&2
  ./scripts/setup-ssh-access.sh
fi

if ! docker context inspect "$DOCKER_CONTEXT" >/dev/null 2>&1; then
  SSH_HOST_VALUE="$SSH_CONTEXT_HOST"

  if [ -n "$SSH_CONTEXT_USER" ]; then
    SSH_HOST_VALUE="${SSH_CONTEXT_USER}@${SSH_CONTEXT_HOST}"
  fi

  echo "Missing Docker context: ${DOCKER_CONTEXT}" >&2
  echo "Creating Docker context ${DOCKER_CONTEXT} with host ssh://${SSH_HOST_VALUE}" >&2
  docker context create "$DOCKER_CONTEXT" --docker "host=ssh://${SSH_HOST_VALUE}"
fi

KUBE_CONTEXT="${KUBE_CONTEXT:?Set KUBE_CONTEXT in .env or environment}"
KIND_PROVISION_ON_BOOTSTRAP="${KIND_PROVISION_ON_BOOTSTRAP:-false}"

if ! kubectl config get-contexts "$KUBE_CONTEXT" >/dev/null 2>&1; then
  echo "Missing Kubernetes context: ${KUBE_CONTEXT}" >&2
  if [ "$KIND_PROVISION_ON_BOOTSTRAP" = "true" ]; then
    echo "Provisioning remote kind cluster prerequisite..." >&2
    ./scripts/provision-kind-cluster.sh
  elif [ "${KUBE_REQUIRED:-false}" = "true" ]; then
    echo "Run ./scripts/provision-kind-cluster.sh first, or set KIND_PROVISION_ON_BOOTSTRAP=true." >&2
    exit 1
  else
    echo "Run ./scripts/provision-kind-cluster.sh later if you want Kubernetes enabled." >&2
  fi
elif ! kubectl --context "$KUBE_CONTEXT" cluster-info >/dev/null 2>&1; then
  echo "Kubernetes context ${KUBE_CONTEXT} exists but is not reachable." >&2
  if [ "$KIND_PROVISION_ON_BOOTSTRAP" = "true" ]; then
    echo "Provisioning remote kind cluster prerequisite..." >&2
    ./scripts/provision-kind-cluster.sh
  elif [ "${KUBE_REQUIRED:-false}" = "true" ]; then
    echo "Run ./scripts/provision-kind-cluster.sh first, or set KIND_PROVISION_ON_BOOTSTRAP=true." >&2
    exit 1
  fi
fi

./scripts/compose-up-remote.sh registry
./scripts/check-remote-registry.sh
./scripts/compose-up-remote.sh registry-ui
./scripts/apply-namespace.sh
