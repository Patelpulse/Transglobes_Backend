#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
REMOTE_HOST="${REMOTE_HOST:-72.61.172.182}"
REMOTE_USER="${REMOTE_USER:-root}"
REMOTE_PORT="${REMOTE_PORT:-22}"
REMOTE_DIR="${REMOTE_DIR:-/var/www/transglobe}"
REPO_URL="${REPO_URL:-$(git -C "$ROOT_DIR" remote get-url origin)}"
BRANCH="${BRANCH:-main}"
APP_NAME="${APP_NAME:-transglobe-backend}"
ENV_SOURCE="${ENV_SOURCE:-$ROOT_DIR/backend/.env}"
SSH_PASSWORD="${SSH_PASSWORD:-}"

log() {
  printf '[deploy] %s\n' "$*"
}

need_password() {
  if [[ -n "$SSH_PASSWORD" ]]; then
    return 0
  fi

  if [[ -t 0 ]]; then
    read -r -s -p "SSH password for ${REMOTE_USER}@${REMOTE_HOST}: " SSH_PASSWORD
    printf '\n'
    export SSH_PASSWORD
    return 0
  fi

  return 1
}

run_expect() {
  local remote_cmd="$1"

  /usr/bin/expect <<EOF
set timeout -1
set host "$REMOTE_HOST"
set user "$REMOTE_USER"
set port "$REMOTE_PORT"
set password "$SSH_PASSWORD"
set command "$remote_cmd"

spawn ssh -p $REMOTE_PORT -o StrictHostKeyChecking=accept-new $REMOTE_USER@$REMOTE_HOST "$remote_cmd"
expect {
  -re "(?i)yes/no" {
    send "yes\r"
    exp_continue
  }
  -re "(?i)password:" {
    send "$SSH_PASSWORD\r"
    exp_continue
  }
  eof
}
EOF
}

copy_env_if_present() {
  if [[ ! -f "$ENV_SOURCE" ]]; then
    log "No local backend/.env found; skipping env sync."
    return 0
  fi

  log "Syncing backend/.env to the VPS."
  /usr/bin/expect <<EOF
set timeout -1
set host "$REMOTE_HOST"
set user "$REMOTE_USER"
set port "$REMOTE_PORT"
set password "$SSH_PASSWORD"
set local_file "$ENV_SOURCE"
set remote_file "$REMOTE_DIR/backend/.env"

spawn scp -P $REMOTE_PORT -o StrictHostKeyChecking=accept-new "$ENV_SOURCE" $REMOTE_USER@$REMOTE_HOST:$REMOTE_DIR/backend/.env
expect {
  -re "(?i)yes/no" {
    send "yes\r"
    exp_continue
  }
  -re "(?i)password:" {
    send "$SSH_PASSWORD\r"
    exp_continue
  }
  eof
}
EOF
}

main() {
  cd "$ROOT_DIR"

  if [[ -z "${SSH_PASSWORD:-}" ]]; then
    if ! need_password; then
      echo "SSH_PASSWORD is required when no interactive terminal is available." >&2
      exit 1
    fi
  fi

  log "Preparing VPS deployment for ${REMOTE_USER}@${REMOTE_HOST}."

  run_expect "mkdir -p '$REMOTE_DIR' && if [ ! -d '$REMOTE_DIR/.git' ]; then git clone --branch '$BRANCH' '$REPO_URL' '$REMOTE_DIR'; else git -C '$REMOTE_DIR' fetch origin '$BRANCH' && git -C '$REMOTE_DIR' reset --hard 'origin/$BRANCH'; fi"

  copy_env_if_present

  run_expect "bash '$REMOTE_DIR/scripts/vps_remote_backend_setup.sh' '$REMOTE_DIR' '$APP_NAME'"

  log "Deployment finished."
}

main "$@"
