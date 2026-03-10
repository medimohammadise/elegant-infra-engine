set -euo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"
if [ ! -f .env ] && [ -f .env.example ]; then
  cp .env.example .env
fi
set -a
source .env
set +a
: "${IMAGE_REGISTRY:?Set IMAGE_REGISTRY in .env or environment}"
: "${IMAGE_NAME:?Set IMAGE_NAME in .env or environment}"
: "${IMAGE_TAG:?Set IMAGE_TAG in .env or environment}"
IMAGE_REF="${IMAGE_REGISTRY}/${IMAGE_NAME}:${IMAGE_TAG}"
BUILD_CONTEXT="${1:-.}"
./scripts/docker-client-env.sh docker build -t "$IMAGE_REF" "$BUILD_CONTEXT"
./scripts/docker-client-env.sh docker push "$IMAGE_REF"
