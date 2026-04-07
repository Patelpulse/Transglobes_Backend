#!/usr/bin/env bash
set -euo pipefail

STAGE_DIR="${1:-/tmp/transglobe-web-staging}"
WEB_ROOT="${2:-/var/www/transglobe-sites}"
NGINX_SITE="/etc/nginx/sites-available/transglobe-websites"
SSL_CERT="/etc/letsencrypt/live/transgloble.com/fullchain.pem"
SSL_KEY="/etc/letsencrypt/live/transgloble.com/privkey.pem"
SSL_OPTIONS="/etc/letsencrypt/options-ssl-nginx.conf"
SSL_DHPARAM="/etc/letsencrypt/ssl-dhparams.pem"

log() {
  printf '[remote-web] %s\n' "$*"
}

ensure_root() {
  if [[ "${EUID:-$(id -u)}" -ne 0 ]]; then
    echo "This script must run as root." >&2
    exit 1
  fi
}

ensure_ssl_files() {
  if [[ ! -f "$SSL_CERT" || ! -f "$SSL_KEY" || ! -f "$SSL_OPTIONS" || ! -f "$SSL_DHPARAM" ]]; then
    echo "Required TLS files are missing. Ensure certbot certificate for transgloble.com exists." >&2
    exit 1
  fi
}

sync_site() {
  local name="$1"
  rm -rf "$WEB_ROOT/$name"
  mkdir -p "$WEB_ROOT/$name"
  cp -R "$STAGE_DIR/$name/." "$WEB_ROOT/$name/"
}

configure_nginx() {
  cat > "$NGINX_SITE" <<EOF_NGINX
server {
  listen 80;
  listen [::]:80;
  server_name transgloble.com www.transgloble.com;
  root ${WEB_ROOT}/root;
  index index.html;

  location /api/ {
    proxy_pass http://127.0.0.1:8080/api/;
    proxy_http_version 1.1;
    proxy_set_header Host \$host;
    proxy_set_header X-Real-IP \$remote_addr;
    proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto \$scheme;
  }

  location /socket.io/ {
    proxy_pass http://127.0.0.1:8080/socket.io/;
    proxy_http_version 1.1;
    proxy_set_header Upgrade \$http_upgrade;
    proxy_set_header Connection "upgrade";
    proxy_set_header Host \$host;
    proxy_set_header X-Real-IP \$remote_addr;
    proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto \$scheme;
  }

  location / {
    try_files \$uri \$uri/ /index.html;
  }
}

server {
  listen 443 ssl;
  listen [::]:443 ssl;
  server_name transgloble.com www.transgloble.com;
  root ${WEB_ROOT}/root;
  index index.html;

  ssl_certificate ${SSL_CERT};
  ssl_certificate_key ${SSL_KEY};
  include ${SSL_OPTIONS};
  ssl_dhparam ${SSL_DHPARAM};

  location /api/ {
    proxy_pass http://127.0.0.1:8080/api/;
    proxy_http_version 1.1;
    proxy_set_header Host \$host;
    proxy_set_header X-Real-IP \$remote_addr;
    proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto \$scheme;
  }

  location /socket.io/ {
    proxy_pass http://127.0.0.1:8080/socket.io/;
    proxy_http_version 1.1;
    proxy_set_header Upgrade \$http_upgrade;
    proxy_set_header Connection "upgrade";
    proxy_set_header Host \$host;
    proxy_set_header X-Real-IP \$remote_addr;
    proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto \$scheme;
  }

  location / {
    try_files \$uri \$uri/ /index.html;
  }
}

server {
  listen 80;
  listen [::]:80;
  server_name admin.transgloble.com;
  root ${WEB_ROOT}/admin;
  index index.html;

  location /api/ {
    proxy_pass http://127.0.0.1:8080/api/;
    proxy_http_version 1.1;
    proxy_set_header Host \$host;
    proxy_set_header X-Real-IP \$remote_addr;
    proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto \$scheme;
  }

  location /socket.io/ {
    proxy_pass http://127.0.0.1:8080/socket.io/;
    proxy_http_version 1.1;
    proxy_set_header Upgrade \$http_upgrade;
    proxy_set_header Connection "upgrade";
    proxy_set_header Host \$host;
    proxy_set_header X-Real-IP \$remote_addr;
    proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto \$scheme;
  }

  location / {
    try_files \$uri \$uri/ /index.html;
  }
}

server {
  listen 443 ssl;
  listen [::]:443 ssl;
  server_name admin.transgloble.com;
  root ${WEB_ROOT}/admin;
  index index.html;

  ssl_certificate ${SSL_CERT};
  ssl_certificate_key ${SSL_KEY};
  include ${SSL_OPTIONS};
  ssl_dhparam ${SSL_DHPARAM};

  location /api/ {
    proxy_pass http://127.0.0.1:8080/api/;
    proxy_http_version 1.1;
    proxy_set_header Host \$host;
    proxy_set_header X-Real-IP \$remote_addr;
    proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto \$scheme;
  }

  location /socket.io/ {
    proxy_pass http://127.0.0.1:8080/socket.io/;
    proxy_http_version 1.1;
    proxy_set_header Upgrade \$http_upgrade;
    proxy_set_header Connection "upgrade";
    proxy_set_header Host \$host;
    proxy_set_header X-Real-IP \$remote_addr;
    proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto \$scheme;
  }

  location / {
    try_files \$uri \$uri/ /index.html;
  }
}

server {
  listen 80;
  listen [::]:80;
  server_name corporate.transgloble.com;
  root ${WEB_ROOT}/corporate;
  index index.html;

  location /api/ {
    proxy_pass http://127.0.0.1:8080/api/;
    proxy_http_version 1.1;
    proxy_set_header Host \$host;
    proxy_set_header X-Real-IP \$remote_addr;
    proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto \$scheme;
  }

  location /socket.io/ {
    proxy_pass http://127.0.0.1:8080/socket.io/;
    proxy_http_version 1.1;
    proxy_set_header Upgrade \$http_upgrade;
    proxy_set_header Connection "upgrade";
    proxy_set_header Host \$host;
    proxy_set_header X-Real-IP \$remote_addr;
    proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto \$scheme;
  }

  location / {
    try_files \$uri \$uri/ /index.html;
  }
}

server {
  listen 443 ssl;
  listen [::]:443 ssl;
  server_name corporate.transgloble.com;
  root ${WEB_ROOT}/corporate;
  index index.html;

  ssl_certificate ${SSL_CERT};
  ssl_certificate_key ${SSL_KEY};
  include ${SSL_OPTIONS};
  ssl_dhparam ${SSL_DHPARAM};

  location /api/ {
    proxy_pass http://127.0.0.1:8080/api/;
    proxy_http_version 1.1;
    proxy_set_header Host \$host;
    proxy_set_header X-Real-IP \$remote_addr;
    proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto \$scheme;
  }

  location /socket.io/ {
    proxy_pass http://127.0.0.1:8080/socket.io/;
    proxy_http_version 1.1;
    proxy_set_header Upgrade \$http_upgrade;
    proxy_set_header Connection "upgrade";
    proxy_set_header Host \$host;
    proxy_set_header X-Real-IP \$remote_addr;
    proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto \$scheme;
  }

  location / {
    try_files \$uri \$uri/ /index.html;
  }
}

server {
  listen 80;
  listen [::]:80;
  server_name driver.transgloble.com;
  root ${WEB_ROOT}/driver;
  index index.html;

  location /api/ {
    proxy_pass http://127.0.0.1:8080/api/;
    proxy_http_version 1.1;
    proxy_set_header Host \$host;
    proxy_set_header X-Real-IP \$remote_addr;
    proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto \$scheme;
  }

  location /socket.io/ {
    proxy_pass http://127.0.0.1:8080/socket.io/;
    proxy_http_version 1.1;
    proxy_set_header Upgrade \$http_upgrade;
    proxy_set_header Connection "upgrade";
    proxy_set_header Host \$host;
    proxy_set_header X-Real-IP \$remote_addr;
    proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto \$scheme;
  }

  location / {
    try_files \$uri \$uri/ /index.html;
  }
}

server {
  listen 443 ssl;
  listen [::]:443 ssl;
  server_name driver.transgloble.com;
  root ${WEB_ROOT}/driver;
  index index.html;

  ssl_certificate ${SSL_CERT};
  ssl_certificate_key ${SSL_KEY};
  include ${SSL_OPTIONS};
  ssl_dhparam ${SSL_DHPARAM};

  location /api/ {
    proxy_pass http://127.0.0.1:8080/api/;
    proxy_http_version 1.1;
    proxy_set_header Host \$host;
    proxy_set_header X-Real-IP \$remote_addr;
    proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto \$scheme;
  }

  location /socket.io/ {
    proxy_pass http://127.0.0.1:8080/socket.io/;
    proxy_http_version 1.1;
    proxy_set_header Upgrade \$http_upgrade;
    proxy_set_header Connection "upgrade";
    proxy_set_header Host \$host;
    proxy_set_header X-Real-IP \$remote_addr;
    proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto \$scheme;
  }

  location / {
    try_files \$uri \$uri/ /index.html;
  }
}
EOF_NGINX

  ln -sf "$NGINX_SITE" /etc/nginx/sites-enabled/transglobe-websites
  rm -f /etc/nginx/sites-enabled/transglobe-backend
  rm -f /etc/nginx/sites-available/transglobe-backend
  rm -f /etc/nginx/sites-enabled/default
  nginx -t
  systemctl enable nginx
  systemctl restart nginx
}

main() {
  ensure_root
  ensure_ssl_files

  log "Syncing web bundles into place."
  sync_site root
  sync_site admin
  sync_site corporate
  sync_site driver

  log "Writing nginx frontend configuration."
  configure_nginx

  log "Frontend websites are now configured."
}

main "$@"
