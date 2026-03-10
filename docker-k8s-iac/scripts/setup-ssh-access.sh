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
require_command ssh-keygen

SSH_CONTEXT_HOST="${DOCKER_CONTEXT_HOST:-${DOCKER_CONTEXT:-}}"
SSH_CONTEXT_USER="${DOCKER_CONTEXT_USER:-}"

if [ -z "$SSH_CONTEXT_HOST" ] || [ -z "$SSH_CONTEXT_USER" ]; then
  echo "Set DOCKER_CONTEXT_HOST and DOCKER_CONTEXT_USER in .env before running this script." >&2
  exit 1
fi

SSH_TARGET="${SSH_CONTEXT_USER}@${SSH_CONTEXT_HOST}"
KEY_PATH="${SSH_KEY_PATH:-$HOME/.ssh/id_ed25519}"
PUB_KEY_PATH="${KEY_PATH}.pub"

if [ ! -f "$KEY_PATH" ]; then
  echo "Creating SSH key at $KEY_PATH"
  ssh-keygen -t ed25519 -f "$KEY_PATH" -N ""
fi

if ! command -v ssh-copy-id >/dev/null 2>&1; then
  echo "Missing required command: ssh-copy-id" >&2
  echo "Install it or copy ${PUB_KEY_PATH} to ${SSH_TARGET}:~/.ssh/authorized_keys manually." >&2
  exit 1
fi

echo "Copying SSH key to ${SSH_TARGET}"
ssh-copy-id -i "$PUB_KEY_PATH" "$SSH_TARGET"

echo "Verifying passwordless SSH access to ${SSH_TARGET}"
ssh -o BatchMode=yes -o ConnectTimeout=10 "$SSH_TARGET" true

echo "SSH setup complete for ${SSH_TARGET}"
