# Changelog

All notable changes to PrayerTimer will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Planned
- Widget support for Notification Center
- Multiple location profiles
- Prayer time notifications with custom sounds
- Qibla direction indicator
- Hijri calendar integration
- Customizable color themes
- Export prayer times to Calendar app

## [1.0.0] - 2025-10-03

### Added
- 🎉 Initial release
- ⏰ Menu bar icon with live countdown timer (e.g., "2h 45m" or "45m")
- 🕌 Complete daily prayer times display (Fajr, Sunrise, Dhuhr, Asr, Maghrib, Isha)
- 🌍 Manual location configuration (city and country input)
- ⚙️ Settings panel with gear icon for easy access
- 🔄 Automatic prayer time updates from Aladhan API
- 🎨 Clean SwiftUI interface with native macOS design
- 🌙 Dark mode support
- 🔒 Persistent background operation (cannot be quit with CMD+Q)
- 📍 Optional automatic location detection
- ⚡ Orange highlight for next prayer with <15 minutes remaining
- 🔁 Manual refresh button for prayer times
- 📱 Widget extension support (foundation)
- 🎯 Next prayer highlighted in prayer list
- ⏱️ Live countdown display in both menu bar and dropdown
- 🏗️ MVVM architecture with SwiftUI
- 📦 SharedDefaults for data persistence
- 🌐 Aladhan API integration
- 🔐 Privacy-focused (no analytics or tracking)

### Technical Details
- **Minimum macOS**: 13.0 (Ventura)
- **Language**: Swift 5.9
- **UI Framework**: SwiftUI
- **API**: Aladhan Prayer Times API
- **Architecture**: MVVM pattern
- **Default Location**: Istanbul, Turkey
- **Calculation Method**: ISNA (Islamic Society of North America)

### Configuration
- Default prayer calculation method: Method 2 (ISNA)
- Countdown update interval: 1 second
- Warning threshold: 15 minutes before prayer
- Location mode: Manual (default)
- App policy: Accessory (no dock icon)

### Files Included
- Complete source code
- Xcode project configuration
- Widget extension
- Info.plist and entitlements
- README.md with full documentation
- LICENSE (MIT)
- CONTRIBUTING.md guidelines
- .gitignore for Xcode/Swift

### Known Limitations
- Cannot be quit using CMD+Q (by design)
- Requires manual installation (not on App Store)
- Internet connection required for fetching prayer times
- Single timezone support (based on location)
- Auto-location may not work without proper permissions

---

## Version Format

- **Major** (X.0.0): Breaking changes or major features
- **Minor** (1.X.0): New features, backward compatible
- **Patch** (1.0.X): Bug fixes, minor improvements

## Types of Changes

- **Added**: New features
- **Changed**: Changes in existing functionality
- **Deprecated**: Soon-to-be removed features
- **Removed**: Removed features
- **Fixed**: Bug fixes
- **Security**: Security improvements

---

[Unreleased]: https://github.com/ummugulsunn/prayertimer/compare/v1.0.0...HEAD
[1.0.0]: https://github.com/ummugulsunn/prayertimer/releases/tag/v1.0.0

