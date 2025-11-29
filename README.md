# SmartExpense iOS App

> A modern iOS expense tracking application

## 📋 Table of Contents

- [Overview](#overview)
- [Requirements](#requirements)
- [Setup](#setup)
- [Architecture](#architecture)
- [Features](#features)
- [Dependencies](#dependencies)
- [Development](#development)
- [Testing](#testing)
- [Deployment](#deployment)
- [Contributing](#contributing)

## 🎯 Overview

SmartExpense is an iOS application designed to help users track and manage their expenses efficiently.

## 📱 Requirements

- iOS 14.0+
- Xcode 14.0+
- Swift 5.7+

## 🚀 Setup

### Prerequisites

1. Install Xcode from the App Store
2. Ensure you have the latest Xcode Command Line Tools:
   ```bash
   xcode-select --install
   ```

### Installation

1. Clone the repository:
   ```bash
   git clone [repository-url]
   cd SmartExpense
   ```

2. Open the project:
   ```bash
   open SmartExpense.xcodeproj
   ```
   or
   ```bash
   open SmartExpense.xcworkspace
   ```

3. Install dependencies (if using Swift Package Manager, they'll be resolved automatically)

4. Build and run:
   - Select a simulator or device
   - Press `Cmd + R` or click Run

## 🏗 Architecture

The app uses an MVVM architecture with feature-based folders.

### Patterns Used

- MVVM (Model-View-ViewModel)

### Project Structure

```
SmartExpense/
├── App/              # App entry point and configuration
├── Features/         # Feature modules
├── Core/             # Core utilities and shared code
├── Resources/        # Assets, strings, fonts
└── Supporting Files/ # Configuration files
```

## ✨ Features

### Home (Insights & Capture)

- Default tab shown on launch.
- Implemented in SwiftUI with a liquid glass aesthetic (blurred glass cards on a warm neutral background).
- KPIs shown as horizontal cards:
  - Total Spend (current period)
  - Average Daily Spend
  - Top Merchant
  - Top Category
- Backed by a `HomeViewModel` which loads a `HomeSummary` via `HomeOverviewServiceProtocol`.
- Source layout:
  - `App/SmartExpenseApp.swift` – SwiftUI app entry and tab bar.
  - `Features/Home/Models/` – Home-specific models such as `HomeSummary`.
  - `Features/Home/ViewModels/` – `HomeViewModel`.
  - `Features/Home/Views/` – `HomeView`, `HomeKPICardView`.
  - `Features/Home/Services/` – `HomeOverviewServiceProtocol`, `HomeOverviewMockService`.

## 📦 Dependencies

### Current Dependencies

_This section will be updated as dependencies are added._

| Package | Version | Purpose |
|---------|---------|---------|
| - | - | - |

### Adding Dependencies

1. Open the project in Xcode
2. Go to File → Add Packages...
3. Enter the package URL
4. Select version requirements
5. Add to the appropriate target

**Note:** All new dependencies must be documented here with their purpose.

## 💻 Development

### Code Style

- Follow Apple's Swift API Design Guidelines
- See [.cursorrules](.cursorrules) for detailed development guidelines

### Git Workflow

1. Create a feature branch: `git checkout -b feature/your-feature-name`
2. Make your changes
3. Commit with descriptive messages
4. Push and create a pull request

### Commit Message Format

```
type: description

[optional body]
```

Types: `feat`, `fix`, `docs`, `refactor`, `test`, `chore`

## 🧪 Testing

### Running Tests

```bash
# Run all tests
xcodebuild test -scheme SmartExpense -destination 'platform=iOS Simulator,name=iPhone 14'

# Run from Xcode
Cmd + U
```

### Test Coverage

_Current test coverage will be tracked here._

## 🚢 Deployment

### Build Configurations

- **Debug**: Development builds with debugging symbols
- **Staging**: Pre-production testing builds
- **Release**: Production builds

### Environment Variables

_List of environment variables and configuration will be documented here._

### Release Process

1. Update version number in Xcode
2. Update CHANGELOG.md
3. Create a release tag
4. Build archive
5. Upload to App Store Connect

## 🤝 Contributing

Please read [CONTRIBUTING.md](CONTRIBUTING.md) for details on our code of conduct and the process for submitting pull requests.

## 📝 Changelog

See [CHANGELOG.md](CHANGELOG.md) for a list of changes and version history.

## 📄 License

_[License information will be added]_

---

**Last Updated:** _This file is automatically maintained. Please update when making significant changes._
