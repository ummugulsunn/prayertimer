#!/usr/bin/env bash
# Yerel Release derlemesi (imza olmadan). Çıktı: build/PrayerTimer-macOS.zip
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"
DERIVED="${DERIVED:-$ROOT/build/DerivedData}"
OUT_ZIP="$ROOT/build/PrayerTimer-macOS.zip"
mkdir -p "$ROOT/build"

echo "==> İkonlar (isteğe bağlı)"
if command -v swift >/dev/null 2>&1; then
	swift "$ROOT/scripts/generate_app_icons.swift" "$ROOT/Sources/Assets.xcassets/AppIcon.appiconset" || true
fi

echo "==> xcodebuild Release"
	xcodebuild -scheme PrayerTimer \
	-configuration Release \
	-destination "platform=macOS" \
	-derivedDataPath "$DERIVED" \
	CODE_SIGN_IDENTITY="-" \
	CODE_SIGNING_ALLOWED=NO \
	build -quiet

APP="$DERIVED/Build/Products/Release/PrayerTimer.app"
if [[ ! -d "$APP" ]]; then
	echo "Hata: $APP bulunamadı" >&2
	exit 1
fi

rm -f "$OUT_ZIP"
ditto -c -k --sequesterRsrc --keepParent "$APP" "$OUT_ZIP"
echo "==> Tamam: $OUT_ZIP"
echo "    İlk açılışta: Sağ tık → Aç (Gatekeeper). Gerekirse: xattr -cr /path/PrayerTimer.app"
