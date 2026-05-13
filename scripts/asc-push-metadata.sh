#!/usr/bin/env bash
# Prayer Timer → App Store Connect metadata (official API via asc).
# Ön koşul: App Store Connect’te uygulama kaydı (aynı bundle id: com.ummugulsun.PrayerTimer).
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
META="$ROOT/AppStore/metadata"

asc metadata validate --dir "$META"

: "${ASC_APP_ID:?Önce ASC’de Prayer Timer uygulamasını oluşturun; asc apps list --bundle-id com.ummugulsun.PrayerTimer ile App ID’yi görün ve export ASC_APP_ID=... yapın}"

VERSION="${ASC_VERSION:-1.0}"

# İlk kez: mağaza sürümü yoksa oluşturur (zaten varsa hata verebilir — o zaman satırı yorumlayın).
asc versions create --app "$ASC_APP_ID" --version "$VERSION" --platform MAC_OS \
  --copyright "${ASC_COPYRIGHT:-2026 Prayer Timer}" || true

asc metadata push --app "$ASC_APP_ID" --version "$VERSION" --platform MAC_OS --dir "$META"

echo "Tamamlandı. İnceleme notları ve ekran görüntüleri hâlâ ASC web arayüzünden veya asc’nin ilgili komutlarıyla tamamlanmalı."
