# 🕌 PrayerTimer - macOS Menu Bar Prayer Times App

A minimal, persistent macOS menu bar application that displays Islamic prayer times with a live countdown timer. Built specifically for personal use with SwiftUI and modern macOS APIs.

![macOS](https://img.shields.io/badge/macOS-13.0+-blue.svg)
![Swift](https://img.shields.io/badge/Swift-5.9-orange.svg)
![License](https://img.shields.io/badge/License-MIT-green.svg)

## ✨ Features

### 🔔 **Always-On Menu Bar Display**
- Persistent menu bar icon with live countdown (e.g., "2h 45m" or "45m")
- Never closes - runs continuously in the background
- No dock icon - purely menu bar focused
- Auto-updates every second
- Orange highlight when less than 15 minutes remain

### ⏰ **Prayer Times Management**
- Displays all 6 daily prayer times (Fajr, Sunrise, Dhuhr, Asr, Maghrib, Isha)
- Highlights the next upcoming prayer
- Live countdown timer in both menu bar and dropdown
- Automatic daily updates

### 🌍 **Flexible Location Settings**
- **Manual Location**: Enter city and country manually (default: Istanbul, Turkey)
- **Automatic Location**: Toggle GPS-based location (optional)
- Easy-to-access settings panel with gear icon

### 🎨 **Modern UI/UX**
- Clean, native macOS design using SwiftUI
- Dark mode support
- Smooth animations and transitions
- Minimal and distraction-free

### 🔐 **Privacy & Security**
- No analytics or tracking
- Location data never leaves your device
- Open source - verify the code yourself

## 📸 Screenshots

*Menu Bar View*
```
🌙 45dk
```

*Dropdown View*
- Header with countdown timer
- Next prayer highlighted in orange
- Full daily prayer schedule
- Settings panel for location configuration

## 🚀 Installation

### Requirements
- macOS 13.0 (Ventura) or later
- Xcode 15.0 or later
- Apple Developer account (for code signing)

### Build from Source

1. **Clone the repository**
```bash
git clone https://github.com/yourusername/prayertimer.git
cd prayertimer
```

2. **Open in Xcode**
```bash
open PrayerTimer.xcodeproj
```

3. **Configure signing**
   - Select the PrayerTimer target
   - Go to "Signing & Capabilities"
   - Select your development team

4. **Build and run**
   - Press `Cmd + R` or click the Run button
   - Grant location permissions if using auto-location

5. **Install permanently**
   - Build for Release configuration
   - Copy `PrayerTimer.app` to `/Applications`
   - Add to Login Items for auto-start

## ⚙️ Configuration

### Setting Your Location

1. Click the menu bar icon (🌙)
2. Click the gear icon (⚙️) in the header
3. Toggle "Otomatik Konum" (Auto Location) OFF
4. Enter your city and country
5. Click "Kaydet ve Güncelle" (Save and Update)

### Default Settings
- **Location Mode**: Manual
- **City**: Istanbul
- **Country**: Turkey
- **Countdown Update**: Every second

## 🏗️ Architecture

### Tech Stack
- **Language**: Swift 5.9
- **UI Framework**: SwiftUI
- **Minimum macOS**: 13.0
- **API**: Aladhan Prayer Times API

### Project Structure
```
PrayerTimer/
├── Sources/
│   ├── App/
│   │   └── PrayerTimerApp.swift       # Main app & menu bar UI
│   ├── Models/
│   │   └── APIResponse.swift          # Data models
│   ├── ViewModels/
│   │   └── PrayerTimeViewModel.swift  # Business logic
│   ├── Services/
│   │   └── PrayerTimeService.swift    # API service
│   ├── Managers/
│   │   ├── LocationManager.swift      # Location handling
│   │   └── NotificationManager.swift  # Notifications
│   └── Shared/
│       ├── SharedDefaults.swift       # UserDefaults wrapper
│       └── TimingsCodec.swift         # JSON codecs
├── PrayerTimerWidget/                 # Widget extension
└── Config/
    └── Info.plist
```

### Key Components

#### **AppDelegate**
- Prevents app termination (`applicationShouldTerminate`)
- Disables dock icon (`.accessory` policy)
- Ensures persistent background operation

#### **MenuBarContentView**
- Main dropdown UI
- Settings panel with location configuration
- Prayer times list with live updates
- Countdown timer display

#### **PrayerTimeViewModel**
- Manages prayer times state
- Handles location (manual/auto)
- Updates countdown every second
- Fetches data from API

## 🔧 Customization

### Changing Prayer Time Calculation Method

Edit `PrayerTimeService.swift`:
```swift
let methodParam = "method=2"  // Change calculation method
```

Supported methods:
- 1: University of Islamic Sciences, Karachi
- 2: Islamic Society of North America (ISNA)
- 3: Muslim World League
- 4: Umm Al-Qura University, Makkah
- 5: Egyptian General Authority of Survey

### Adjusting Warning Time

Edit `PrayerTimerApp.swift`:
```swift
.foregroundColor(minutes < 15 ? .orange : .primary)
// Change 15 to your preferred warning threshold
```

## 🐛 Troubleshooting

### App Won't Start
- Check macOS version (13.0+ required)
- Verify code signing configuration
- Check Console.app for error messages

### Prayer Times Not Loading
1. Open Settings panel (gear icon)
2. Verify city/country spelling
3. Click "Kaydet ve Güncelle" to refresh
4. Check internet connection

### Menu Bar Icon Not Appearing
- Quit and relaunch the app
- Check System Settings > Menu Bar settings
- Ensure app has proper permissions

### Countdown Not Updating
- App automatically starts countdown on launch
- Verify the app is running (check Activity Monitor)
- If frozen, force quit and relaunch

## 🚫 Known Limitations

- **Cannot be quit normally**: Use Activity Monitor to force quit
- **Manual installation required**: Not available on App Store
- **Requires internet**: For fetching prayer times
- **Single timezone**: Based on provided location only

## 🛠️ Development

### Running in Debug Mode
```bash
xcodebuild -project PrayerTimer.xcodeproj -scheme PrayerTimer -configuration Debug build
```

### Building for Release
```bash
xcodebuild -project PrayerTimer.xcodeproj -scheme PrayerTimer -configuration Release build
```

### Code Signing
Update `project.yml` with your team ID:
```yaml
DEVELOPMENT_TEAM: "YOUR_TEAM_ID"
```

## 📝 API Reference

This app uses the [Aladhan Prayer Times API](https://aladhan.com/prayer-times-api):

**Endpoint**: `https://api.aladhan.com/v1/timingsByCity`

**Parameters**:
- `city`: City name (e.g., "Istanbul")
- `country`: Country name (e.g., "Turkey")
- `method`: Calculation method (default: 2)

## 🤝 Contributing

This is a personal project, but suggestions and improvements are welcome!

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- [Aladhan API](https://aladhan.com/) for prayer times data
- Apple's SwiftUI framework for modern UI development
- Islamic Society of North America (ISNA) for calculation methods

## 📧 Contact

Created for personal use by [@ummugulsun](https://github.com/ummugulsun)

---

**Note**: This app was built for personal use and may not cover all edge cases or regional variations. Use at your own discretion and always verify prayer times with local mosques or authorities.

## 🎯 Roadmap

Future improvements (maybe):
- [ ] Widget support for Notification Center
- [ ] Multiple location profiles
- [ ] Prayer time notifications
- [ ] Qibla direction indicator
- [ ] Hijri calendar integration
- [ ] Customizable themes

---

Made with ❤️ for the Muslim community

