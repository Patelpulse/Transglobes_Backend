#!/usr/bin/env bash
set -euo pipefail

APP_DIR="${1:-/var/www/transglobe}"
SERVICE_NAME="${2:-transglobe-backend}"
BACKEND_DIR="$APP_DIR/backend"
NODE_BINARY="${NODE_BINARY:-/usr/bin/node}"
PORT="${PORT:-8080}"
NGINX_SITE="/etc/nginx/sites-available/${SERVICE_NAME}"

log() {
  printf '[remote] %s\n' "$*"
}

ensure_root() {
  if [[ "${EUID:-$(id -u)}" -ne 0 ]]; then
    echo "This script must run as root." >&2
    exit 1
  fi
}

install_packages() {
  export DEBIAN_FRONTEND=noninteractive
  apt-get update -y
  apt-get install -y git curl ca-certificates nginx

  if ! command -v node >/dev/null 2>&1 || ! command -v npm >/dev/null 2>&1; then
    curl -fsSL https://deb.nodesource.com/setup_20.x | bash -
    apt-get install -y nodejs
  fi
}

install_deps() {
  cd "$BACKEND_DIR"
  if [[ -f package-lock.json ]]; then
    if npm ci --omit=dev; then
      return 0
    fi
  fi

  npm install --omit=dev
}

ensure_env() {
  if [[ -f "$BACKEND_DIR/.env" ]]; then
    return 0
  fi

  cat > "$BACKEND_DIR/.env" <<EOF
PORT=${PORT}
NODE_ENV=production
# Fill in the application secrets below if the deploy script did not sync a local backend/.env.
# MONGODB_URI=
# JWT_SECRET=
# SMTP_USER=
# SMTP_PASS=
# TWILIO_SID=
# TWILIO_AUTH_TOKEN=
# TWILIO_PHONE=
EOF
}

configure_systemd() {
  cat > "/etc/systemd/system/${SERVICE_NAME}.service" <<EOF
[Unit]
Description=Transglobe backend service
After=network.target

[Service]
Type=simple
WorkingDirectory=${BACKEND_DIR}
EnvironmentFile=${BACKEND_DIR}/.env
Environment=NODE_ENV=production
ExecStart=${NODE_BINARY} ${BACKEND_DIR}/server.js
Restart=always
RestartSec=5
User=root
Group=root

[Install]
WantedBy=multi-user.target
EOF

  systemctl daemon-reload
  systemctl enable --now "${SERVICE_NAME}.service"
  systemctl restart "${SERVICE_NAME}.service"
}

configure_nginx() {
  cat > "$NGINX_SITE" <<EOF
server {
  listen 80;
  listen [::]:80;
  server_name _;

  location / {
    proxy_pass http://127.0.0.1:${PORT};
    proxy_http_version 1.1;
    proxy_set_header Host \$host;
    proxy_set_header X-Real-IP \$remote_addr;
    proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto \$scheme;
    proxy_set_header Upgrade \$http_upgrade;
    proxy_set_header Connection "upgrade";
    proxy_read_timeout 300;
  }
}
EOF

  ln -sf "$NGINX_SITE" "/etc/nginx/sites-enabled/${SERVICE_NAME}"
  rm -f /etc/nginx/sites-enabled/default
  nginx -t
  systemctl enable nginx
  systemctl restart nginx
}

main() {
  ensure_root
  cd "$APP_DIR"

  log "Installing server packages."
  install_packages

  log "Ensuring application files are present."
  if [[ ! -d "$BACKEND_DIR" ]]; then
    echo "Backend directory not found: $BACKEND_DIR" >&2
    exit 1
  fi

  ensure_env

  log "Installing backend dependencies."
  install_deps

  log "Configuring systemd service."
  configure_systemd

  log "Configuring Nginx reverse proxy."
  configure_nginx

  log "Backend is now running on port ${PORT} behind Nginx."
}

main "$@"
