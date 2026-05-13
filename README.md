# Prayer Timer — macOS menü çubuğu namaz vakitleri

[![macOS](https://img.shields.io/badge/macOS-13.0+-blue.svg)](https://www.apple.com/macos/)
[![Swift](https://img.shields.io/badge/Swift-5.9-orange.svg)](https://swift.org/)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
[![Build](https://github.com/ummugulsunn/prayertimer/actions/workflows/macos-build.yml/badge.svg)](https://github.com/ummugulsunn/prayertimer/actions/workflows/macos-build.yml)

**English:** A full-featured, open-source **macOS menu bar** app: Islamic prayer times, live countdown, optional location, calculation methods, local notifications, and an optional **widget** (same App Group). Data source: **[Aladhan API](https://aladhan.com/prayer-times-api)** (`/v1/timings`) with correct **IANA timezone** handling and **Imsak** when provided by the API.

**Türkçe:** Tam işlevli **menü çubuğu** uygulaması: günlük namaz vakitleri, sıradaki vakte geri sayım, manuel veya otomatik konum, hesaplama yöntemi seçimi, yerel bildirimler ve isteğe bağlı **widget**. Vakitler **Aladhan** üzerinden çekilir; sunucunun döndürdüğü **saat dilimi** ile birleştirilir (sapma riski azaltılmıştır).

---

## Kurulum (GitHub’dan — herkes için)

### Yöntem A — Hazır `.app` (önerilen)

1. GitHub’da **[Actions](https://github.com/ummugulsunn/prayertimer/actions/workflows/macos-build.yml)** sekmesine gidin.  
2. Son başarılı iş akışına tıklayın → **Artifacts** → **`PrayerTimer-macOS`** ZIP’ini indirin.  
3. ZIP’i açın, **`PrayerTimer.app`** dosyasını **Uygulamalar** (`/Applications`) klasörüne sürükleyin.  
4. **İlk açılış (imzasız derleme):** Uygulamaya **Sağ tık → Aç** deyin; “bilinmeyen geliştirici” uyarısında **Aç**’ı onaylayın.  
   Gerekirse Terminal: `xattr -cr /Applications/PrayerTimer.app`

> CI çıktısı **Apple Developer ile imzalanmaz**; bu yüzden Gatekeeper uyarısı normaldir. Kendi Apple hesabınızla Xcode’dan Archive edip dağıtırsanız uyarı azalır veya kaybolur.

### Yöntem B — Kaynak koddan kendin derle (ZIP üret)

```bash
git clone https://github.com/ummugulsunn/prayertimer.git
cd prayertimer
./scripts/build-release.sh
```

Çıktı: `build/PrayerTimer-macOS.zip` (içinde `PrayerTimer.app`). İkonlar derlemeden önce `scripts/generate_app_icons.swift` ile güncellenir.

### Yöntem C — Xcode

```bash
git clone https://github.com/ummugulsunn/prayertimer.git
cd prayertimer
open PrayerTimer.xcodeproj
```

- **Signing & Capabilities** içinde kendi **Team**’inizi seçin (cihazınızda çalıştırmak için).  
- **Product → Run** (`⌘R`).  
- Yayın için: **Product → Archive → Distribute App**.

### Gereksinimler

- macOS **13.0** (Ventura) veya üzeri  
- **Xcode 15+** (kaynak derlemek için)  
- Namaz verisi için **İnternet**  
- Otomatik konum için: Sistem Ayarları → Gizlilik ve Güvenlik → **Konum Hizmetleri**

---

## Özellikler

| Özellik | Açıklama |
|--------|----------|
| Menü çubuğu | Ay/hilal ikonu + kalan süre; son 1 saatte saniye hassasiyeti |
| Açılır panel | Tüm vakitler, ayarlar, yenileme, hata/başarı mesajları |
| Konum | Manuel şehir/ülke veya isteğe bağlı GPS |
| Hesaplama | Aladhan `method` (Türkiye Diyanet ile uyumlu seçenek dahil) |
| Bildirimler | Yerel bildirim + “X dk önce” hatırlatma |
| Widget | Uygulama ile aynı App Group üzerinden (hedefi Xcode’da açık tutun) |
| Çıkış | Panelde **Çıkış…** veya **⇧⌘Q**; yanlışlıkla **⌘Q** ile kapanmayı zorlaştırır |

---

## Ekran görüntüleri

Menü çubuğu ve panel için `screenshots/` klasörüne bakın (`menubar.png`, `app-view.png`).

---

## Uygulama ikonu

Kaynak: `Sources/Assets.xcassets/AppIcon.appiconset/` (tüm macOS boyutları).  
Yeniden üretmek için:

```bash
swift scripts/generate_app_icons.swift Sources/Assets.xcassets/AppIcon.appiconset
```

---

## Mimari (kısa)

```
Sources/
  App/PrayerTimerApp.swift      # @main, MenuBarExtra, ayarlar paneli
  ViewModels/PrayerTimeViewModel.swift
  Services/PrayerTimeService.swift   # api.aladhan.com/v1/timings
  Shared/TimingsCodec.swift, SharedDefaults.swift
PrayerTimerWidget/            # macOS widget uzantısı
```

- **Sandbox:** ağ istemcisi + App Group.  
- **XcodeGen:** `project.yml` → `xcodegen generate` ile `PrayerTimer.xcodeproj` yenilenebilir.

---

## App Store / ASC

Ayrıntılar: [`APP_STORE_CONNECT.md`](APP_STORE_CONNECT.md) ve `AppStore/metadata/` (örnek mağaza metinleri). CLI: `scripts/asc-push-metadata.sh`.

---

## Sorun giderme

| Sorun | Çözüm |
|-------|--------|
| “Bilinmeyen geliştirici” | Sağ tık → Aç; veya `xattr -cr …/PrayerTimer.app` |
| Menü çubuğunda ikon yok | Bartender/Hidden Bar; uygulama çalışıyor mu kontrol edin |
| Vakitler yüklenmiyor | İnternet; şehir/ülke yazımı; **Kaydet ve Güncelle** |
| Widget boş | Uygulamayı en az bir kez açıp vakit çekin; App Group imzaları aynı team olmalı |

---

## API

- **Base:** `https://api.aladhan.com/v1/timings`  
- **Parametreler:** `date`, `latitude`, `longitude`, `method`  
- **Yanıt:** `data.timings` + `data.meta.timezone` (IANA)

---

## Katkı ve lisans

1. Fork → dal aç → PR  
2. [MIT License](LICENSE)

Teşekkürler: [Aladhan](https://aladhan.com/), SwiftUI, topluluk geri bildirimleri.

---

**Not:** Resmi cami / Diyanet cetveli ile birebir aynılık her zaman garanti edilmez; kritik günlerde yerel kaynakla doğrulama önerilir.
