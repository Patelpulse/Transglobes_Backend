#!/usr/bin/env bash
# Client release APKs — API: https://api.transgloble.com
# Run on a machine where Flutter/Android Gradle can execute (avoid permission issues on some external disks).
#
# Usage from repo root:
#   chmod +x scripts/build_client_apks.sh
#   ./scripts/build_client_apks.sh
#
# Outputs (default flutter-apk location):
#   user_app/build/app/outputs/flutter-apk/app-release.apk
#   driver_app/build/app/outputs/flutter-apk/app-release.apk
#   corporate_panel/build/app/outputs/flutter-apk/app-release.apk
#   admin_app/build/app/outputs/flutter-apk/app-release.apk

set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
API="https://api.transgloble.com"

echo "==> User app"
cd "$ROOT/user_app"
fvm flutter pub get
fvm flutter build apk --release --dart-define="API_BASE_URL=$API"

echo "==> Driver app (dart-define overrides .env for this build)"
cd "$ROOT/driver_app"
fvm flutter pub get
fvm flutter build apk --release \
  --dart-define="API_BASE_URL=$API" \
  --dart-define="SOCKET_BASE_URL=$API"

echo "==> Corporate panel"
cd "$ROOT/Corporate Panel"
fvm flutter pub get
fvm flutter build apk --release

echo "==> Admin app"
cd "$ROOT/admin_app"
fvm flutter pub get
fvm flutter build apk --release

OUT="$ROOT/dist/client_apks"
mkdir -p "$OUT"
cp -f "$ROOT/user_app/build/app/outputs/flutter-apk/app-release.apk" "$OUT/transglobe-user-release.apk"
cp -f "$ROOT/driver_app/build/app/outputs/flutter-apk/app-release.apk" "$OUT/transglobe-driver-release.apk"
cp -f "$ROOT/Corporate Panel/build/app/outputs/flutter-apk/app-release.apk" "$OUT/transglobe-corporate-release.apk"
cp -f "$ROOT/admin_app/build/app/outputs/flutter-apk/app-release.apk" "$OUT/transglobe-admin-release.apk"

echo ""
echo "Done. API: $API"
echo "ZIP this folder for the client:"
echo "  $OUT"
ls -la "$OUT"
