#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
REMOTE_HOST="${REMOTE_HOST:-72.61.172.182}"
REMOTE_USER="${REMOTE_USER:-root}"
REMOTE_PORT="${REMOTE_PORT:-22}"
REPO_URL="${REPO_URL:-$(git -C "$ROOT_DIR" remote get-url origin)}"
BRANCH="${BRANCH:-main}"
SSH_PASSWORD="${SSH_PASSWORD:-}"
REMOTE_STAGE_DIR="${REMOTE_STAGE_DIR:-/tmp/transglobe-web-staging}"
REMOTE_WEB_DIR="${REMOTE_WEB_DIR:-/var/www/transglobe-sites}"
BACKEND_DEPLOY_SCRIPT="${BACKEND_DEPLOY_SCRIPT:-$ROOT_DIR/scripts/deploy_backend_vps.sh}"
WEBSITE_SETUP_SCRIPT="${WEBSITE_SETUP_SCRIPT:-$ROOT_DIR/scripts/vps_remote_websites_setup.sh}"
STAGE_ROOT="${STAGE_ROOT:-/tmp/transglobe-web-builds}"
FVM_VERSION="${FVM_VERSION:-3.38.4}"

log() {
  printf '[web-deploy] %s\n' "$*"
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

  REMOTE_HOST="$REMOTE_HOST" \
  REMOTE_USER="$REMOTE_USER" \
  REMOTE_PORT="$REMOTE_PORT" \
  SSH_PASSWORD="$SSH_PASSWORD" \
  REMOTE_CMD="$remote_cmd" \
  /usr/bin/expect <<'EOF'
set timeout -1
set host $env(REMOTE_HOST)
set user $env(REMOTE_USER)
set port $env(REMOTE_PORT)
set password $env(SSH_PASSWORD)
set command $env(REMOTE_CMD)

set ssh_args [list ssh -p $port -o StrictHostKeyChecking=accept-new ${user}@${host} $command]
spawn {*}$ssh_args
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

run_scp() {
  local local_path="$1"
  local remote_path="$2"

  REMOTE_HOST="$REMOTE_HOST" \
  REMOTE_USER="$REMOTE_USER" \
  REMOTE_PORT="$REMOTE_PORT" \
  SSH_PASSWORD="$SSH_PASSWORD" \
  LOCAL_FILE="$local_path" \
  REMOTE_FILE="$remote_path" \
  /usr/bin/expect <<'EOF'
set timeout -1
set host $env(REMOTE_HOST)
set user $env(REMOTE_USER)
set port $env(REMOTE_PORT)
set password $env(SSH_PASSWORD)
set local_file $env(LOCAL_FILE)
set remote_file $env(REMOTE_FILE)

set scp_args [list scp -P $port -o StrictHostKeyChecking=accept-new -r $local_file ${user}@${host}:$remote_file]
spawn {*}$scp_args
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

flutter_bin() {
  local app_dir="$1"
  printf '%s/.fvm/versions/%s/bin/flutter' "$app_dir" "$FVM_VERSION"
}

build_web_app() {
  local app_dir="$1"
  local stage_name="$2"
  local flutter_path
  flutter_path="$(flutter_bin "$app_dir")"

  log "Building ${stage_name} web bundle."
  (cd "$app_dir" && PUB_CACHE="$HOME/.pub-cache" "$flutter_path" pub get)
  (cd "$app_dir" && PUB_CACHE="$HOME/.pub-cache" "$flutter_path" build web --release)

  rm -rf "$STAGE_ROOT/$stage_name"
  mkdir -p "$STAGE_ROOT/$stage_name"
  cp -R "$app_dir/build/web/." "$STAGE_ROOT/$stage_name/"
}

main() {
  cd "$ROOT_DIR"

  if [[ -z "${SSH_PASSWORD:-}" ]]; then
    if ! need_password; then
      echo "SSH_PASSWORD is required when no interactive terminal is available." >&2
      exit 1
    fi
  fi

  rm -rf "$STAGE_ROOT"
  mkdir -p "$STAGE_ROOT"

  build_web_app "$ROOT_DIR/user_app" "root"
  build_web_app "$ROOT_DIR/admin_app" "admin"
  build_web_app "$ROOT_DIR/Corporate Panel" "corporate"
  build_web_app "$ROOT_DIR/driver_app" "driver"

  log "Refreshing backend service and API proxy."
  "$BACKEND_DEPLOY_SCRIPT"

  log "Preparing remote web staging directory."
  run_expect "rm -rf '$REMOTE_STAGE_DIR' '$REMOTE_WEB_DIR' && mkdir -p '$REMOTE_STAGE_DIR' '$REMOTE_WEB_DIR'"

  log "Uploading built web bundles."
  run_scp "$STAGE_ROOT/root" "$REMOTE_STAGE_DIR/"
  run_scp "$STAGE_ROOT/admin" "$REMOTE_STAGE_DIR/"
  run_scp "$STAGE_ROOT/corporate" "$REMOTE_STAGE_DIR/"
  run_scp "$STAGE_ROOT/driver" "$REMOTE_STAGE_DIR/"

  log "Configuring nginx for the frontend sites."
  run_expect "bash '$WEBSITE_SETUP_SCRIPT' '$REMOTE_STAGE_DIR' '$REMOTE_WEB_DIR'"

  log "Website deployment finished."
}

main "$@"
