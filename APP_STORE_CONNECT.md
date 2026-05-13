# App Store Connect – Prayer Timer (macOS)

Apple hesabınıza ve tarayıcıda oturum açmaya ben erişemem; aşağıdakiler **yayına hazırlık + ASC’ye yapıştırılabilir metinler**. Xcode’da **Archive → Distribute App → App Store Connect** ile yüklemeniz gerekir.

## 1. Apple Developer ön koşullar

1. **Apple Developer Program** üyeliği (ücretli).
2. [Certificates, Identifiers & Profiles](https://developer.apple.com/account):
   - **App ID**: `com.ummugulsun.PrayerTimer` (Sandbox, App Groups, Location güncelleme*)
   - **App ID**: `com.ummugulsun.PrayerTimerWidget` (Sandbox, App Groups)
   - **App Group**: `group.com.ummugulsun.prayertimer` (her iki hedefe bağlı)
3. Xcode’da **Signing & Capabilities**: Team seçili, **Automatically manage signing** açık.

\*Konum yalnızca kullanıcı “Otomatik konum” açtığında istenir.

## 2. App Store Connect’te uygulama oluşturma

1. [App Store Connect](https://appstoreconnect.apple.com) → **My Apps** → **+** → **New App**
2. **Platforms**: macOS  
3. **Name**: Prayer Timer  
4. **Primary Language**: Turkish veya English (metadata hangi dilde yazdıysanız)  
5. **Bundle ID**: `com.ummugulsun.PrayerTimer` (Developer’da oluşturduğunuz ile aynı)  
6. **SKU**: Örn. `prayertimer-mac-001` (benzersiz, kullanıcıya görünmez)

## 3. App bilgisi (metadata) – yapıştırılabilir

### Türkçe

**Alt başlık (subtitle, ~30 karakter)**  
Namaz vakitleri ve geri sayım

**Promosyon metni (isteğe bağlı)**  
Menü çubuğunda günlük namaz vakitleri ve sıradaki vakte geri sayım. İsterseniz şehir/ülke veya otomatik konum ile hesaplama.

**Açıklama**  
Prayer Timer, macOS menü çubuğunda İslami namaz vakitlerini gösteren hafif bir uygulamadır.

• Günlük vakitler (İmsak, Güneş, Öğle, İkindi, Akşam, Yatsı)  
• Sıradaki vakte geri sayım  
• Manuel şehir/ülke veya isteğe bağlı otomatik konum  
• Hesaplama yöntemi seçimi (Aladhan API, Diyanet ile uyumlu yöntem dahil)  
• Yerel bildirim ve hatırlatma seçenekleri  
• İsteğe bağlı widget ile paylaşılan veri  

İnternet bağlantısı namaz vakitlerini almak için gereklidir. Konum yalnızca otomatik konum etkinse kullanılır ve dışarı gönderilmez.

**Anahtar kelimeler** (virgülle, ~100 karakter)  
namaz,vakit,ezan,islam,imsak,hijri,mac,menü çubuğu

**Destek URL’si**  
Kendi GitHub README veya destek sayfanızın tam adresi (zorunlu).

**Gizlilik politikası URL’si**  
Yayında olması **zorunlu**; kişisel veri toplamadığınızı ve konum/API kullanımını özetleyen kısa bir sayfa hazırlayın.

### English (uluslararası liste için isteğe bağlı)

**Subtitle**  
Prayer times & countdown for Mac

**Description**  
Prayer Timer shows Islamic prayer times in the macOS menu bar with a countdown to the next prayer. Choose manual city/country or optional automatic location, pick a calculation method, and optionally enable local reminders. Prayer times are fetched online (Aladhan API). Location is used only when you enable automatic location.

## 4. App Privacy (Gizlilik) – önerilen yanıtlar

**Veri toplanıyor mu?** Genelde **Hayır** veya çok minimal:

| Soru tipi | Öneri |
|-----------|--------|
| **Konum** | “Approximate Location” — **Collected**: Hayır veya **Linked to user**: Hayır — **Purpose**: App functionality (yalnızca otomatik konum açıksa). Şeffaflık: Yaklaşık konum API hesaplaması için kullanılır, sunucuya kayıtlı kullanıcı profili oluşturulmaz. |
| **İletişim bilgisi / Tanımlayıcılar** | Yok |
| **Tanılama** | Yok (Crash analytics kullanmıyorsanız) |

**Üçüncü taraf**: Namaz verisi **Aladhan** (`api.aladhan.com`) üzerinden çekilir — “Üçüncü taraf ile paylaşım” için ASC sorularına göre ya **hayır** ya da API sağlayıcı bilgisini kontrol ederek işaretleyin (çoğu küçük uygulama “tracking” kullanmaz).

## 5. İnceleme notları (Review Notes – İngilizce önerilir)

```
Prayer Timer is a menu bar-only macOS app (LSUIElement/accessory).
• Users quit via Shift+Cmd+Q or the in-app Quit confirmation in the popover footer (standard Cmd+Q is intentionally blocked to avoid accidental quit).
• Prayer times are fetched from https://api.aladhan.com (HTTPS only).
• Location is requested only when the user enables “automatic location”; otherwise manual city/country is used with geocoding on-device APIs.
• Notifications are local only (UNUserNotificationCenter).
• App Sandbox enabled; network client + app group for widget sharing.
```

## 6. Ekran görüntüları (macOS)

Mağaza gereksinimleri zaman zaman güncellenir; yükleme sırasında ASC eksik çözünürlük uyarısı verir.

Tipik olarak **1280×800**, **1440×900**, **2560×1600** gibi geniş formatlar iş görür — Xcode Simulator veya gerçek Mac’ten PNG/JPEG.

## 7. Sürüm ve yükleme

- **Versiyon** (`CFBundleShortVersionString`): örn. `1.0`  
- **Build** (`CFBundleVersion`): her yüklemede artırın (`1`, `2`, …)

Xcode: **Product → Archive → Distribute App → App Store Connect → Upload**. İlk yüklemeden sonra ASC’de build seçip **Submit for Review**.

## 8. Olası red gerekçeleri ve hazırlık

- **Gizlilik politikası eksik** → Mutlaka URL ekleyin.  
- **Menü çubuğu / çıkış davranışı** → Yukarıdaki Review Notes’a bağlantı verin.  
- **Konum kullanımı** → Info.plist’te `NSLocationWhenInUseUsageDescription` mevcut; kullanıcıya net açıklama yeterli.

Bu dosya yalnızca rehberdir; hukuk veya mağaza politikası için gerekirse danışmanlık alın.

## 9. `asc` CLI (kurulu — API ile metadata)

Bu makinede **`asc doctor`** temiz; API anahtarı **GlowIsland** profili üzerinden çalışıyor. **`com.ummugulsun.PrayerTimer` için henüz ASC kaydı yok** — otomatik oluşturma için **`asc web apps create`** tarayıcı/Apple ID oturumu istiyor; bu ortamda şifre veya önbellekli web oturumu olmadığı için uygulama kaydını **senin terminalinde** oluşturmalısın:

```bash
asc web apps create \
  --name "Prayer Timer" \
  --bundle-id com.ummugulsun.PrayerTimer \
  --sku PRAYERTIMER_MAC_001 \
  --platform MAC_OS \
  --primary-locale tr \
  --apple-id "APPLE_ID_EMAILIN"
```

Öncesinde [Identifiers](https://developer.apple.com/account/resources/identifiers/list) üzerinde **`com.ummugulsun.PrayerTimer`** App ID tanımlı olmalı.

Repo içinde doğrulanmış metadata klasörü:

- `AppStore/metadata/` — `asc metadata validate` geçti  
- Yükleme: App ID’yi öğrendikten sonra:

```bash
export ASC_APP_ID="675..."   # asc apps list --bundle-id com.ummugulsun.PrayerTimer
./scripts/asc-push-metadata.sh
```

**Not:** `privacyPolicyUrl` ve `supportUrl` şu an `https://ummugulsunn.github.io/prayertimer` altına işaret ediyor; GitHub Pages’te bu sayfalar yoksa oluştur veya JSON içindeki URL’leri güncelle.

