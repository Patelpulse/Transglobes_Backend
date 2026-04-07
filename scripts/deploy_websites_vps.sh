#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
REMOTE_HOST="${REMOTE_HOST:-72.61.172.182}"
REMOTE_USER="${REMOTE_USER:-root}"
REMOTE_PORT="${REMOTE_PORT:-22}"
REPO_URL="${REPO_URL:-$(git -C "$ROOT_DIR" remote get-url origin)}"
BRANCH="${BRANCH:-main}"
SSH_PASSWORD="${SSH_PASSWORD:-}"
REMOTE_REPO_DIR="${REMOTE_REPO_DIR:-/var/www/transglobe}"
REMOTE_STAGE_DIR="${REMOTE_STAGE_DIR:-/tmp/transglobe-web-staging}"
REMOTE_WEB_DIR="${REMOTE_WEB_DIR:-/var/www/transglobe-sites}"
BACKEND_DEPLOY_SCRIPT="${BACKEND_DEPLOY_SCRIPT:-$ROOT_DIR/scripts/deploy_backend_vps.sh}"
WEBSITE_SETUP_SCRIPT="${WEBSITE_SETUP_SCRIPT:-$REMOTE_REPO_DIR/scripts/vps_remote_websites_setup.sh}"
STAGE_ROOT="${STAGE_ROOT:-/tmp/transglobe-web-builds}"
FVM_VERSION="${FVM_VERSION:-3.38.4}"
SKIP_WEB_BUILDS="${SKIP_WEB_BUILDS:-false}"
WEB_WASM_DRY_RUN="${WEB_WASM_DRY_RUN:-false}"

log() {
  printf '[web-deploy] %s\n' "$*"
}

to_lower() {
  printf '%s' "$1" | tr '[:upper:]' '[:lower:]'
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

stage_web_bundle() {
  local app_dir="$1"
  local stage_name="$2"

  if [[ ! -d "$app_dir/build/web" ]]; then
    echo "Missing web build output for ${stage_name} at ${app_dir}/build/web." >&2
    exit 1
  fi

  rm -rf "$STAGE_ROOT/$stage_name"
  mkdir -p "$STAGE_ROOT/$stage_name"
  cp -R "$app_dir/build/web/." "$STAGE_ROOT/$stage_name/"
}

build_web_app() {
  local app_dir="$1"
  local stage_name="$2"
  local flutter_path
  local -a wasm_args
  flutter_path="$(flutter_bin "$app_dir")"
  wasm_args=()

  if [[ "$(to_lower "$WEB_WASM_DRY_RUN")" != "true" ]]; then
    wasm_args+=(--no-wasm-dry-run)
  fi

  log "Building ${stage_name} web bundle."
  (cd "$app_dir" && PUB_CACHE="$HOME/.pub-cache" "$flutter_path" pub get)
  (cd "$app_dir" && PUB_CACHE="$HOME/.pub-cache" "$flutter_path" build web --release "${wasm_args[@]}")
  stage_web_bundle "$app_dir" "$stage_name"
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

  if [[ "$(to_lower "$SKIP_WEB_BUILDS")" == "true" ]]; then
    log "Skipping web builds and reusing existing build/web bundles."
    stage_web_bundle "$ROOT_DIR/user_app" "root"
    stage_web_bundle "$ROOT_DIR/admin_app" "admin"
    stage_web_bundle "$ROOT_DIR/Corporate Panel" "corporate"
    stage_web_bundle "$ROOT_DIR/driver_app" "driver"
  else
    build_web_app "$ROOT_DIR/user_app" "root"
    build_web_app "$ROOT_DIR/admin_app" "admin"
    build_web_app "$ROOT_DIR/Corporate Panel" "corporate"
    build_web_app "$ROOT_DIR/driver_app" "driver"
  fi

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
