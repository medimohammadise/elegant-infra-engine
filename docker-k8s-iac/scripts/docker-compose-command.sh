set -euo pipefail

if docker compose version >/dev/null 2>&1; then
  printf '%s\n' 'docker compose'
  exit 0
fi

if command -v docker-compose >/dev/null 2>&1; then
  printf '%s\n' 'docker-compose'
  exit 0
fi

echo "Missing Docker Compose support. Install the Docker Compose plugin or docker-compose." >&2
exit 1
