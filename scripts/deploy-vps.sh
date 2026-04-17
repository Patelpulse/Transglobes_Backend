#!/usr/bin/env bash
# Deploy Transglobe backend + Flutter web builds to VPS (72.61.172.182).
# Prereqs: ssh root@72.61.172.182, fvm flutter, npm on server.
#
# Server layout (existing):
#   Backend:  /var/www/transglobe/backend  → pm2 name: transglobe-backend
#   Node must listen on PORT=8080 (nginx `transglobe-websites` & IP site proxy here).
# Static by IP (optional nginx site `transglobe-ip`):
#   /var/www/transglobe-ip/web/{admin,user,driver,corporate}/
#
# Usage (from repo root):
#   chmod +x scripts/deploy-vps.sh
#   ./scripts/deploy-vps.sh

set -euo pipefail

VPS="${VPS:-root@72.61.172.182}"
REMOTE_BACKEND="${REMOTE_BACKEND:-/var/www/transglobe/backend}"
REMOTE_WEB_IP="${REMOTE_WEB_IP:-/var/www/transglobe-ip/web}"
REMOTE_WEB_DOMAINS="${REMOTE_WEB_DOMAINS:-/var/www/transglobe-sites}"
REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"

echo "==> Repo: $REPO_ROOT"

echo "==> Building Flutter web (admin, user, driver, corporate)..."
cd "$REPO_ROOT/admin_app"
fvm flutter pub get
fvm flutter build web --release --base-href /admin/

cd "$REPO_ROOT/user_app"
fvm flutter pub get
fvm flutter build web --release --base-href /user/

cd "$REPO_ROOT/driver_app"
fvm flutter pub get
fvm flutter build web --release --base-href /driver/

cd "$REPO_ROOT/Corporate Panel"
fvm flutter pub get
fvm flutter build web --release --base-href /corporate/

echo "==> Rsync backend + web to $VPS..."
ssh "$VPS" "mkdir -p '$REMOTE_WEB_IP/admin' '$REMOTE_WEB_IP/user' '$REMOTE_WEB_IP/driver' '$REMOTE_WEB_IP/corporate' '$REMOTE_WEB_DOMAINS/root' '$REMOTE_WEB_DOMAINS/admin' '$REMOTE_WEB_DOMAINS/driver' '$REMOTE_WEB_DOMAINS/corporate'"

rsync -avz --delete \
  --exclude node_modules \
  --exclude .git \
  "$REPO_ROOT/backend/" "$VPS:$REMOTE_BACKEND/"

rsync -avz --delete "$REPO_ROOT/admin_app/build/web/" "$VPS:$REMOTE_WEB_IP/admin/"
rsync -avz --delete "$REPO_ROOT/user_app/build/web/" "$VPS:$REMOTE_WEB_IP/user/"
rsync -avz --delete "$REPO_ROOT/driver_app/build/web/" "$VPS:$REMOTE_WEB_IP/driver/"
rsync -avz --delete "$REPO_ROOT/Corporate Panel/build/web/" "$VPS:$REMOTE_WEB_IP/corporate/"

# Domain-based web roots (transgloble.com + subdomains)
rsync -avz --delete "$REPO_ROOT/user_app/build/web/" "$VPS:$REMOTE_WEB_DOMAINS/root/"
rsync -avz --delete "$REPO_ROOT/admin_app/build/web/" "$VPS:$REMOTE_WEB_DOMAINS/admin/"
rsync -avz --delete "$REPO_ROOT/driver_app/build/web/" "$VPS:$REMOTE_WEB_DOMAINS/driver/"
rsync -avz --delete "$REPO_ROOT/Corporate Panel/build/web/" "$VPS:$REMOTE_WEB_DOMAINS/corporate/"

echo "==> Remote: npm install + pm2 restart transglobe-backend..."
ssh "$VPS" bash -s <<REMOTE
set -euo pipefail
cd '$REMOTE_BACKEND'
if ! grep -q '^PORT=' .env 2>/dev/null; then
  echo 'PORT=8080' >> .env
  echo "Appended PORT=8080 to .env (avoid conflict with nginx on 8082)."
fi
npm install --omit=dev
if command -v pm2 >/dev/null 2>&1; then
  pm2 restart transglobe-backend || pm2 start server.js --name transglobe-backend --cwd '$REMOTE_BACKEND'
  pm2 save
else
  echo "pm2 not installed"
  exit 1
fi
REMOTE

echo ""
echo "==> If not already installed, enable IP nginx site (HTTP):"
echo "    scp scripts/nginx-transglobe-vps.conf $VPS:/etc/nginx/sites-available/transglobe-ip"
echo "    ssh $VPS 'sudo ln -sf /etc/nginx/sites-available/transglobe-ip /etc/nginx/sites-enabled/transglobe-ip && sudo nginx -t && sudo systemctl reload nginx'"
echo ""
echo "Done."
echo "  API (IP):   http://72.61.172.182:8085/api/version"
echo "  Admin:      http://72.61.172.182:8085/admin/"
echo "  User:       http://72.61.172.182:8085/user/"
echo "  Driver:     http://72.61.172.182:8085/driver/"
echo "  Corporate:  http://72.61.172.182:8085/corporate/"
echo "  Production HTTPS: https://api.transgloble.com — admin/driver/corporate *.transgloble.com"
