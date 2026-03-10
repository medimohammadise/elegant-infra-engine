set -euo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"
if [ ! -f .env ] && [ -f .env.example ]; then
  cp .env.example .env
fi
set -a
source .env
set +a
: "${DOCKER_CONTEXT:?Set DOCKER_CONTEXT in .env or environment}"
COMPOSE_COMMAND="$(./scripts/docker-compose-command.sh)"

if [ "$COMPOSE_COMMAND" = "docker compose" ]; then
  ./scripts/docker-client-env.sh docker --context "$DOCKER_CONTEXT" compose down
else
  ./scripts/docker-client-env.sh docker-compose down
fi
