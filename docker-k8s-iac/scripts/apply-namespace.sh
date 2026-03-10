set -euo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"
if [ ! -f .env ] && [ -f .env.example ]; then
  cp .env.example .env
fi
set -a
source .env
set +a
KUBECTL_ARGS=()
if [ -n "${KUBE_CONTEXT:-}" ]; then
  KUBECTL_ARGS+=(--context "$KUBE_CONTEXT")
fi
KUBE_REQUIRED="${KUBE_REQUIRED:-false}"

if ! kubectl "${KUBECTL_ARGS[@]}" cluster-info >/dev/null 2>&1; then
  if [ "$KUBE_REQUIRED" = "true" ]; then
    echo "Kubernetes context ${KUBE_CONTEXT:-current-context} is not reachable." >&2
    exit 1
  fi

  echo "Kubernetes context ${KUBE_CONTEXT:-current-context} is not reachable; skipping namespace apply." >&2
  exit 0
fi

kubectl "${KUBECTL_ARGS[@]}" apply -f k8s/namespace.yaml
