<h1 dir="auto"><img src="Sources/Assets.xcassets/AppIcon.appiconset/icon_128.png" width="36" height="36" alt="Prayer Timer app icon" style="vertical-align: middle; margin-right: 10px;"> PrayerTimer</h1>

**PrayerTimer** is a native **macOS menu bar** application that shows Islamic prayer times and a live countdown to the next prayer. It is built with **SwiftUI**, uses the **Aladhan** prayer-times API, and supports manual or automatic location, calculation methods, local notifications, and an optional **widget** extension.

[![macOS](https://img.shields.io/badge/macOS-13.0+-0A84FF?style=flat-square)](https://www.apple.com/macos/)
[![Swift](https://img.shields.io/badge/Swift-5.9-F05138?style=flat-square)](https://swift.org/)
[![License](https://img.shields.io/badge/License-MIT-22C55E?style=flat-square)](LICENSE)
[![Build](https://img.shields.io/github/actions/workflow/status/ummugulsunn/prayertimer/macos-build.yml?branch=main&style=flat-square&label=CI)](https://github.com/ummugulsunn/prayertimer/actions/workflows/macos-build.yml)

---

## Table of contents

1. [Features](#features)
2. [Screenshots](#screenshots)
3. [Requirements](#requirements)
4. [Installation](#installation)
5. [Configuration](#configuration)
6. [Project layout](#project-layout)
7. [Architecture](#architecture)
8. [Customization](#customization)
9. [Troubleshooting](#troubleshooting)
10. [API reference](#api-reference)
11. [Distribution and App Store](#distribution-and-app-store)
12. [Contributing](#contributing)
13. [License](#license)
14. [Acknowledgments](#acknowledgments)

---

## Features

| Area | Description |
|------|-------------|
| **Menu bar** | Persistent icon with compact countdown (hours/minutes or minutes). Adaptive refresh: finer updates when the next prayer is soon; coarser when far away. Orange emphasis within about 15 minutes of the next prayer. |
| **Schedule** | Six daily times (Fajr through Isha; UI labels follow Turkish naming). Next prayer is highlighted. |
| **Popover** | Full list, large countdown, refresh, settings, and status messages. |
| **Location** | Manual city and country (defaults: Istanbul, Turkey), or optional Core Location–based coordinates. |
| **Methods** | In-app picker mapped to Aladhan `method` identifiers (see `CalculationMethod.swift`). |
| **Notifications** | Local notifications and optional pre-prayer reminders. |
| **Widget** | macOS widget shares data via App Group `group.com.ummugulsun.prayertimer`. |
| **Privacy** | No bundled analytics SDKs. Network calls are HTTPS to Aladhan; location is only requested when auto-location is enabled. |

---

## Screenshots

**Menu bar**

![Menu bar with countdown](screenshots/menubar.png)

*Countdown next to the icon.*

**Popover**

![Popover with schedule and settings](screenshots/app-view.png)

*Next prayer, countdown, daily list, and settings.*

---

## Requirements

| Item | Version / note |
|------|------------------|
| macOS | 13.0 (Ventura) or later |
| Xcode | 15 or later (to build from source) |
| Network | Required to fetch prayer times |
| Apple Developer Program | Required only for your own signing, TestFlight, or Mac App Store distribution |

---

## Installation

### From source (recommended for developers)

1. Clone the repository.

   ```bash
   git clone https://github.com/ummugulsunn/prayertimer.git
   cd prayertimer
   ```

2. Open the Xcode project.

   ```bash
   open PrayerTimer.xcodeproj
   ```

3. Select the **PrayerTimer** target, open **Signing & Capabilities**, and assign your **Team**.

4. Build and run with **Product → Run** (`⌘R`). Grant location access if you use automatic location.

5. To keep the app installed, build **Release**, copy `PrayerTimer.app` to `/Applications`, and optionally add it under **System Settings → General → Login Items**.

### Pre-built archive (CI or local script)

- **GitHub Actions:** open the [macOS build workflow](https://github.com/ummugulsunn/prayertimer/actions/workflows/macos-build.yml), pick the latest successful run, and download the **PrayerTimer-macOS** artifact (ZIP containing `PrayerTimer.app`).
- **Local:** from the repository root, run `./scripts/build-release.sh`. Output: `build/PrayerTimer-macOS.zip`.

Unsigned builds may trigger Gatekeeper on first launch. Use **Control-click → Open**, or run `xattr -cr /path/to/PrayerTimer.app` if needed.

### App icons (optional regeneration)

```bash
swift scripts/generate_app_icons.swift Sources/Assets.xcassets/AppIcon.appiconset
```

---

## Configuration

1. Click the menu bar icon.
2. Open **Settings** (gear control).
3. Turn **Otomatik Konum** off for manual city and country, or on for GPS.
4. Press **Kaydet ve Güncelle** to refresh times from the network.

**Defaults:** manual mode, Istanbul / Turkey, adaptive countdown (most frequent when the next prayer is within one hour).

---

## Project layout

```
PrayerTimer/
├── Sources/
│   ├── App/                 PrayerTimerApp.swift (MenuBarExtra, popover, commands)
│   ├── Models/              API models, calculation enums
│   ├── ViewModels/          PrayerTimeViewModel
│   ├── Services/            PrayerTimeService
│   ├── Managers/            LocationManager, NotificationManager
│   ├── Shared/              SharedDefaults, TimingsCodec
│   ├── Views/               ContentView (previews / auxiliary UI)
│   └── Assets.xcassets/     Application icons
├── PrayerTimerWidget/       Widget extension
├── Config/                  Info.plist
├── scripts/                 build-release.sh, icon generator, ASC helpers
├── AppStore/metadata/       Example App Store Connect copy (optional)
├── APP_STORE_CONNECT.md     Notes for App Store Connect
└── project.yml              XcodeGen definition (optional)
```

---

## Architecture

- **PrayerTimerApp** — Application entry point: `MenuBarExtra`, popover content, keyboard shortcuts, accessibility labels.
- **PrayerTimeViewModel** — Owns schedule and countdown state, persists settings, coordinates notifications and widget reloads.
- **PrayerTimeService** — Performs `GET` requests to Aladhan; decodes timings and `meta.timezone`.
- **TimingsCodec** — Combines API time strings with the correct IANA time zone; prefers **Imsak** when the API supplies it separately from Fajr.
- **Sandbox** — Declared in entitlements: outbound network, App Group for the widget. No user-selected file entitlement.

**Quitting:** use **Shift+⌘Q** (*Prayer Timer'dan Çıkış*) or **Quit…** in the popover footer. Standard **⌘Q** is deliberately inconvenient to reduce accidental exits from a menu bar–only app.

---

## Customization

- **Calculation method:** use the in-app picker. Reference IDs and labels live in `CalculationMethod.swift` and the [Aladhan API documentation](https://aladhan.com/prayer-times-api).
- **“Urgent” window (orange):** adjust the minute threshold in `PrayerTimerApp.swift` where the menu bar label chooses orange vs default foreground.

---

## Troubleshooting

| Symptom | What to try |
|---------|-------------|
| App will not open after download | Control-click the app → **Open**; or clear quarantine: `xattr -cr /Applications/PrayerTimer.app` |
| No icon in the menu bar | Confirm the process is running; check for menu bar management utilities that hide icons |
| Times do not load | Check network; verify city and country strings; use **Kaydet ve Güncelle** |
| Widget is empty | Launch the main app at least once so shared defaults are populated; verify App Group and signing match for both targets |
| Countdown stalls | Relaunch; if the app is hung, quit from Activity Monitor and reopen |

---

## API reference

| Item | Value |
|------|--------|
| Base URL | `https://api.aladhan.com/v1/timings` |
| Query | `date` (`DD-MM-YYYY`), `latitude`, `longitude`, optional `method` |
| Response | `data.timings` (string times) and `data.meta.timezone` (IANA zone used when building `Date` values) |

Official documentation: [Aladhan Prayer Times API](https://aladhan.com/prayer-times-api).

---

## Distribution and App Store

Default CI artifacts are **not** signed with a Developer ID. For public distribution without Gatekeeper friction, sign with your Apple Developer account or follow Mac App Store procedures.

See **`APP_STORE_CONNECT.md`** and **`AppStore/metadata/`** for optional App Store Connect copy and `asc` workflow notes (`scripts/asc-push-metadata.sh`).

---

## Contributing

1. Fork the repository.  
2. Create a branch (`git checkout -b feature/your-change`).  
3. Commit with clear messages.  
4. Open a pull request against `main`.

Suggestions and bug reports are welcome.

---

## License

This project is released under the **MIT License**. See [LICENSE](LICENSE).

---

## Acknowledgments

- [Aladhan](https://aladhan.com/) for prayer time data and API documentation  
- Apple SwiftUI and platform frameworks  

Maintainer: [@ummugulsunn](https://github.com/ummugulsunn)

---

**Disclaimer:** Third-party prayer-time services may differ slightly from official local timetables. When accuracy is critical, compare with your mosque or national authority.

### Roadmap

| Status | Item |
|--------|------|
| Done | Widget and shared container |
| Done | Local notifications |
| Open | Multiple saved locations |
| Open | Qibla direction |
| Open | Hijri calendar integration |
| Open | Additional themes |

---

PrayerTimer is maintained for the benefit of the Muslim community and anyone who needs a simple macOS prayer-time companion.
