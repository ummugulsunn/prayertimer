# PrayerTimer — macOS Menu Bar Prayer Times

A focused, open-source **macOS menu bar** application that shows Islamic prayer times with a live countdown to the next prayer. Built with **SwiftUI** and modern system APIs (notifications, optional location, optional widget).

![macOS](https://img.shields.io/badge/macOS-13.0+-blue.svg)
![Swift](https://img.shields.io/badge/Swift-5.9-orange.svg)
![License](https://img.shields.io/badge/License-MIT-green.svg)
[![Build](https://github.com/ummugulsunn/prayertimer/actions/workflows/macos-build.yml/badge.svg)](https://github.com/ummugulsunn/prayertimer/actions/workflows/macos-build.yml)

---

## Features

### Always-on menu bar display
- Persistent menu bar icon with countdown (e.g. `2h 45m` or `45m`)
- Runs as a **menu bar–only** app (no Dock icon by default)
- **Adaptive refresh** for efficiency: per-second updates when under one hour; coarser updates when more time remains
- Orange emphasis when the next prayer is within **15 minutes**

### Prayer times
- Full daily schedule (Imsak/Fajr through Isha; labels follow the Turkish UI)
- Highlights the **next** upcoming prayer
- Countdown in both the menu bar label and the popover
- Automatic refresh when the day rolls over; manual refresh available

### Location & methods
- **Manual location**: city and country (defaults: Istanbul, Turkey)
- **Automatic location**: optional Core Location–based coordinates
- **Calculation method** picker (Aladhan `method` codes; includes Turkey-aligned options)

### Experience & privacy
- Native SwiftUI layout, dark-mode friendly
- **No analytics SDKs**; prayer data is fetched over HTTPS from Aladhan
- Location is used **only** when you enable automatic location; geocoding uses system services

### Optional widget
- macOS widget extension shares cached timings via **App Group** (`group.com.ummugulsun.prayertimer`)

---

## Screenshots

**Menu bar** — live countdown next to the icon:

![Menu Bar](screenshots/menubar.png)

**Popover** — schedule, next prayer, settings, and refresh:

![App View](screenshots/app-view.png)

---

## Installation

### Requirements
- **macOS 13.0** (Ventura) or later  
- **Xcode 15+** if you build from source  
- **Internet** to fetch prayer times  
- An **Apple Developer** account only if you need your own signing for distribution or TestFlight

### Option A — Pre-built app (GitHub Actions)

1. Open **[Actions → macOS build](https://github.com/ummugulsunn/prayertimer/actions/workflows/macos-build.yml)**.  
2. Select the latest successful run → **Artifacts** → download **`PrayerTimer-macOS`**.  
3. Unzip and drag **`PrayerTimer.app`** into `/Applications`.  
4. **First launch (unsigned CI build):** Control-click the app → **Open**, then confirm. If macOS still blocks it:  
   `xattr -cr /Applications/PrayerTimer.app`

### Option B — Build a release ZIP locally

```bash
git clone https://github.com/ummugulsunn/prayertimer.git
cd prayertimer
./scripts/build-release.sh
```

Output: `build/PrayerTimer-macOS.zip` containing `PrayerTimer.app`.

### Option C — Xcode (recommended for developers)

```bash
git clone https://github.com/ummugulsunn/prayertimer.git
cd prayertimer
open PrayerTimer.xcodeproj
```

1. Select the **PrayerTimer** target → **Signing & Capabilities** → your **Team**.  
2. **Product → Run** (`⌘R`).  
3. For distribution: **Product → Archive → Distribute App**.

### Optional: regenerate app icons

```bash
swift scripts/generate_app_icons.swift Sources/Assets.xcassets/AppIcon.appiconset
```

---

## Configuration

### Location
1. Click the menu bar icon.  
2. Open **Settings** (gear).  
3. Turn **Otomatik Konum** off for manual city/country, or on for GPS.  
4. Tap **Kaydet ve Güncelle** to refetch times.

### Defaults
- Manual location: **Istanbul**, **Turkey**  
- Calculation method: configurable in settings  
- Notifications: optional local alerts and pre-prayer reminders  

### Quitting the app
- **Shift+⌘Q** — *Prayer Timer'dan Çıkış* from the app menu, or use **Quit…** in the popover footer with confirmation.  
- Standard **⌘Q** is intentionally awkward to avoid accidental quit from a menu bar app.

---

## Architecture

### Tech stack
| Layer | Choice |
|--------|--------|
| Language | Swift 5.9 |
| UI | SwiftUI |
| Minimum OS | macOS 13.0 |
| Data | [Aladhan](https://aladhan.com/prayer-times-api) `GET /v1/timings` (lat/long + `method` + calendar date) |

### Project layout
```
PrayerTimer/
├── Sources/
│   ├── App/                 PrayerTimerApp.swift (MenuBarExtra, popover, commands)
│   ├── Models/              API models, calculation enums
│   ├── ViewModels/          PrayerTimeViewModel (schedule, countdown, persistence)
│   ├── Services/            PrayerTimeService (network)
│   ├── Managers/            Location, notifications
│   ├── Shared/              App Group defaults, timings codec
│   ├── Views/               ContentView (standalone / previews)
│   └── Assets.xcassets/     App icons
├── PrayerTimerWidget/       Widget extension
├── Config/Info.plist
├── project.yml              XcodeGen source of truth (optional)
└── scripts/                 build-release, generate_app_icons, ASC helpers
```

### Notable types
- **`PrayerTimerApp`** — `@main` scene with `MenuBarExtra`, settings popover, accessibility labels.  
- **`PrayerTimeViewModel`** — owns schedule state, debounced settings persistence, adaptive countdown work items, widget/notifications refresh.  
- **`PrayerTimeService`** — ephemeral `URLSession`, decodes `meta.timezone` for correct wall-clock assembly.  
- **`TimingsCodec`** — builds `Date` values in the API timezone; prefers **`Imsak`** when present vs generic Fajr-only strings.

---

## Customization

### Calculation method
Use the in-app picker (backed by `CalculationMethod` and Aladhan `method` IDs). For reference, Aladhan documents many methods [here](https://aladhan.com/prayer-times-api).

### “Urgent” threshold (orange)
The ~15 minute rule lives in the menu bar label styling in `PrayerTimerApp.swift` / view model–driven state; adjust the minute comparison if you want a different window.

---

## Troubleshooting

| Issue | What to try |
|--------|----------------|
| App won’t open after download | Control-click → **Open**; or `xattr -cr` on the `.app` bundle |
| No menu bar icon | Check third-party menu bar managers; confirm the process is running |
| Times look wrong | Refresh; verify city/country; compare with local authority — third-party APIs can differ slightly |
| Widget empty | Launch the main app once after install so timings sync into the App Group |

---

## Known limitations

- **Distribution**: CI artifacts are **unsigned**; for the smoothest end-user experience, sign with your own Apple Developer ID or distribute via the Mac App Store. See [`APP_STORE_CONNECT.md`](APP_STORE_CONNECT.md) for ASC notes.  
- **Internet required** for live fetches (cached/widget data may be stale offline).  
- **Single place** per configuration — one coordinate or manual city at a time.

---

## Development

```bash
# Debug build
xcodebuild -project PrayerTimer.xcodeproj -scheme PrayerTimer -configuration Debug build

# Release (unsigned, from repo root)
./scripts/build-release.sh
```

Regenerate the Xcode project from `project.yml` (if you use [XcodeGen](https://github.com/yonaskolb/XcodeGen)):

```bash
xcodegen generate
```

Set your team in `project.yml` (`DEVELOPMENT_TEAM`) or in Xcode signing settings.

---

## API reference

This project uses the **[Aladhan Prayer Times API](https://aladhan.com/prayer-times-api)**.

| Item | Value |
|------|--------|
| Endpoint | `https://api.aladhan.com/v1/timings` |
| Query | `date` (DD-MM-YYYY in the location’s civil calendar), `latitude`, `longitude`, optional `method` |
| Response | `data.timings` (string times) and `data.meta.timezone` (IANA zone used for parsing) |

---

## Contributing

1. Fork the repository  
2. Create a feature branch (`git checkout -b feature/your-change`)  
3. Commit with clear messages  
4. Open a Pull Request  

Suggestions and fixes are welcome.

---

## License

This project is licensed under the **MIT License** — see [LICENSE](LICENSE).

---

## Acknowledgments

- [Aladhan](https://aladhan.com/) for prayer times data and documentation  
- Apple’s SwiftUI and platform frameworks  

---

## Contact

Maintainer: [@ummugulsunn](https://github.com/ummugulsunn)

---

**Disclaimer:** Prayer times from any API should be cross-checked with your local mosque or official timetable when precision matters. This software is provided as-is.

## Roadmap (ideas)

- [x] Widget + shared container  
- [x] Local notifications  
- [ ] Multiple saved locations  
- [ ] Qibla direction  
- [ ] Hijri calendar integration  
- [ ] Additional themes  

---

Made with care for the Muslim community.
