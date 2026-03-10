set -euo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"
if [ ! -f .env ] && [ -f .env.example ]; then
  cp .env.example .env
fi
set -a
source .env
set +a
REGISTRY_ENDPOINT="${REGISTRY_URL%/}/v2/"
ATTEMPTS="${1:-15}"
SLEEP_SECONDS="${2:-2}"

for attempt in $(seq 1 "$ATTEMPTS"); do
  if curl -fsSL "$REGISTRY_ENDPOINT" >/dev/null; then
    exit 0
  fi

  if [ "$attempt" -lt "$ATTEMPTS" ]; then
    sleep "$SLEEP_SECONDS"
  fi
done

echo "Registry is not reachable at ${REGISTRY_ENDPOINT}" >&2
exit 1
