# Contributing to PrayerTimer

First off, thank you for considering contributing to PrayerTimer! 🎉

## 📋 Table of Contents

- [Code of Conduct](#code-of-conduct)
- [How Can I Contribute?](#how-can-i-contribute)
- [Development Setup](#development-setup)
- [Style Guidelines](#style-guidelines)
- [Commit Messages](#commit-messages)

## 🤝 Code of Conduct

This project is meant for personal use but welcomes contributions. Please be respectful and constructive in all interactions.

## 💡 How Can I Contribute?

### Reporting Bugs

If you find a bug, please create an issue with:

- **Clear title**: Summarize the problem
- **Description**: Detailed explanation of the issue
- **Steps to reproduce**: How to recreate the bug
- **Expected behavior**: What should happen
- **Actual behavior**: What actually happens
- **System info**: macOS version, Xcode version
- **Screenshots**: If applicable

### Suggesting Features

Feature suggestions are welcome! Please include:

- **Use case**: Why this feature is needed
- **Proposed solution**: How it could work
- **Alternatives**: Other approaches you've considered
- **Additional context**: Screenshots, examples, etc.

### Pull Requests

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Make your changes
4. Test thoroughly
5. Commit your changes (see commit message guidelines below)
6. Push to your fork
7. Open a Pull Request

#### Pull Request Checklist

- [ ] Code builds without errors
- [ ] Follows Swift style guidelines
- [ ] No new compiler warnings
- [ ] Tested on macOS 13.0+
- [ ] Updated README if needed
- [ ] Added comments for complex logic

## 🛠️ Development Setup

### Prerequisites

- macOS 13.0 or later
- Xcode 15.0 or later
- Basic understanding of SwiftUI
- Apple Developer account (for code signing)

### Getting Started

```bash
# Clone your fork
git clone https://github.com/yourusername/prayertimer.git
cd prayertimer

# Open in Xcode
open PrayerTimer.xcodeproj

# Configure signing with your team
# (Xcode → Project Settings → Signing & Capabilities)

# Build and run
# Press Cmd+R or click Run button
```

### Project Structure

```
Sources/
├── App/                    # Main app and menu bar UI
├── Models/                 # Data models
├── ViewModels/            # Business logic
├── Services/              # API and external services
├── Managers/              # System managers (location, notifications)
└── Shared/                # Shared utilities
```

## 📝 Style Guidelines

### Swift Code Style

- **Indentation**: Use tabs (as per project configuration)
- **Line length**: Max 120 characters
- **Naming**:
  - Types: `PascalCase`
  - Functions/Variables: `camelCase`
  - Constants: `camelCase`
- **SwiftUI**: Use declarative syntax
- **Comments**: Use `//` for single-line, `/* */` for multi-line

### Code Example

```swift
// Good ✅
struct MenuBarContentView: View {
    @ObservedObject var viewModel: PrayerTimeViewModel
    @State private var showSettings = false
    
    var body: some View {
        VStack(spacing: 0) {
            headerView
            mainContentView
        }
    }
    
    private var headerView: some View {
        // Implementation
    }
}

// Avoid ❌
struct menuBarContentView: View {
    @ObservedObject var VM: PrayerTimeViewModel
    
    var body: some View {
        VStack(spacing:0){  // Bad spacing
            // Everything in one place
        }
    }
}
```

### SwiftUI Best Practices

- Extract complex views into computed properties
- Use `@State` for local state, `@ObservedObject` for shared state
- Avoid business logic in views - use ViewModels
- Use async/await for asynchronous operations

## 📦 Commit Messages

Follow the [Conventional Commits](https://www.conventionalcommits.org/) specification:

### Format

```
<type>(<scope>): <description>

[optional body]

[optional footer]
```

### Types

- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation changes
- `style`: Code style changes (formatting, no logic change)
- `refactor`: Code refactoring
- `perf`: Performance improvements
- `test`: Adding or updating tests
- `chore`: Build process or auxiliary tool changes

### Examples

```bash
# Good ✅
feat(menu-bar): add settings panel for manual location
fix(countdown): correct timer update interval
docs(readme): update installation instructions
refactor(viewmodel): simplify prayer time calculation

# Avoid ❌
updated stuff
fixed bug
changes
```

## 🔍 Code Review Process

1. **Automated checks**: Code must build successfully
2. **Manual review**: Maintainer will review your code
3. **Feedback**: Address any requested changes
4. **Approval**: Once approved, PR will be merged

## 🧪 Testing

Currently, the project doesn't have automated tests, but manual testing is essential:

- Test all menu bar interactions
- Verify countdown timer updates
- Check settings panel functionality
- Test with different locations
- Verify prayer times accuracy

## 📚 Resources

- [SwiftUI Documentation](https://developer.apple.com/documentation/swiftui/)
- [Swift Style Guide](https://google.github.io/swift/)
- [Aladhan API Docs](https://aladhan.com/prayer-times-api)

## ❓ Questions?

Feel free to open an issue for any questions about contributing!

---

Thank you for contributing to PrayerTimer! 🕌

