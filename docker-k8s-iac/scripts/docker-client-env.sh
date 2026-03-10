set -euo pipefail

DOCKER_CONFIG_DIR="${DOCKER_CONFIG:-$HOME/.docker}"
DOCKER_CONFIG_FILE="${DOCKER_CONFIG_DIR}/config.json"

if [ ! -f "$DOCKER_CONFIG_FILE" ]; then
  exit 0
fi

CREDS_STORE="$(sed -n 's/.*"credsStore"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' "$DOCKER_CONFIG_FILE" | head -n 1)"

if [ -z "$CREDS_STORE" ]; then
  exit 0
fi

if command -v "docker-credential-${CREDS_STORE}" >/dev/null 2>&1; then
  exit 0
fi

TMP_DOCKER_CONFIG="$(mktemp -d)"
trap 'rm -rf "$TMP_DOCKER_CONFIG"' EXIT

if [ -d "${DOCKER_CONFIG_DIR}/contexts" ]; then
  cp -R "${DOCKER_CONFIG_DIR}/contexts" "${TMP_DOCKER_CONFIG}/contexts"
fi

sed '/"credsStore"[[:space:]]*:/d' "$DOCKER_CONFIG_FILE" > "${TMP_DOCKER_CONFIG}/config.json"

echo "Docker credential helper docker-credential-${CREDS_STORE} is missing; using a temporary clean Docker config." >&2
DOCKER_CONFIG="$TMP_DOCKER_CONFIG" "$@"
