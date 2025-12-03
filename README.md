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
│   └── SmartExpenseApp.swift
├── Core/             # Core infrastructure
│   └── Data/         # Data persistence layer
│       └── Persistence.swift  # CoreData persistence controller
├── Features/         # Feature modules
│   ├── Capture/      # Receipt and voice expense capture
│   │   ├── Models/   # CaptureOption, ExtractedReceiptData
│   │   ├── Services/ # OCR, Speech Recognition, File Storage, Permissions
│   │   ├── ViewModels/ # ReceiptEditViewModel
│   │   └── Views/    # Capture flow views (Camera, Voice, Edit, etc.)
│   ├── History/      # Expense history and management
│   │   ├── Models/   # ReceiptGroup
│   │   └── Views/    # HistoryView, ExpenseRowView
│   └── Home/         # Home feature (dashboard with KPIs)
│       ├── Models/   # HomeSummary
│       ├── Views/    # HomeView, HomeKPICardView
│       ├── ViewModels/ # HomeViewModel
│       └── Services/ # HomeOverviewServiceProtocol, HomeOverviewMockService
├── Shared/           # Shared components across features
│   └── Views/        # ExpenseDetailView
└── SmartExpenseTests/ # Unit tests
```

## ✨ Features

### Home (Insights & Dashboard)

- Default tab shown on launch.
- Implemented in SwiftUI with a liquid glass aesthetic (blurred glass cards on a warm neutral background).
- KPIs shown as horizontal cards:
  - Total Spend (current period)
  - Average Daily Spend
  - Top Merchant
  - Top Category
- Backed by a `HomeViewModel` which loads a `HomeSummary` via `HomeOverviewServiceProtocol`.
- Currently uses `HomeOverviewMockService` for mock data until persistence layer is fully integrated.
- Source layout:
  - `App/SmartExpenseApp.swift` – SwiftUI app entry and tab bar.
  - `Features/Home/Models/` – Home-specific models such as `HomeSummary`.
  - `Features/Home/ViewModels/` – `HomeViewModel`.
  - `Features/Home/Views/` – `HomeView`, `HomeKPICardView`.
  - `Features/Home/Services/` – `HomeOverviewServiceProtocol`, `HomeOverviewMockService`.

### Capture (Receipt & Voice Expense)

- Full-featured expense capture system with multiple input methods:
  - **Camera Capture**: Take photos of receipts using device camera
  - **Photo Library**: Select existing receipt images from photo library
  - **Voice Input**: Record voice expenses with speech-to-text transcription
  - **Manual Entry**: Direct manual expense entry
- **OCR Processing**: Automatic text extraction from receipt images using Vision framework
  - Extracts merchant name, date, total amount, and line items
  - Parses receipt structure and itemized details
- **Voice Recognition**: Speech-to-text transcription with expense parsing
  - Extracts amount, merchant, and category from natural language
- **Receipt Editing**: Full editing interface for reviewing and correcting extracted data
  - Edit merchant details, dates, amounts
  - Add, edit, or remove line items
  - Assign categories to items and merchants
- **File Storage**: Secure local storage of receipt images
- **Permissions Management**: Handles camera, photo library, and microphone permissions
- Source layout:
  - `Features/Capture/Models/` – `CaptureOption`, `ExtractedReceiptData`
  - `Features/Capture/Services/` – `ReceiptOCRService`, `SpeechRecognitionService`, `VoiceExpenseParser`, `FileStorageService`, `PermissionsManager`
  - `Features/Capture/ViewModels/` – `ReceiptEditViewModel`
  - `Features/Capture/Views/` – `CaptureCoordinatorView`, `CaptureMenuView`, `ImagePickerView`, `ImagePreviewView`, `ProcessingView`, `ReceiptEditView`, `VoiceRecordingView`, `VoiceExpenseReviewView`, `LineItemRowView`

### History (Expense Management)

- Fully implemented expense history and management tab.
- CoreData-backed list view showing all captured receipts and expenses.
- Features:
  - **Grouped Display**: Expenses grouped by date (Today, Yesterday, This Week, Last Week, Earlier)
  - **Expense List**: Shows merchant name, date, amount, and category
  - **Detail View**: Full expense details with line items and receipt images
  - **CRUD Operations**: Create, read, update, and delete expenses
  - **Empty State**: Helpful empty state when no expenses exist
  - **Capture Integration**: Quick access to capture flow from history tab
- Source layout:
  - `Features/History/Models/` – `ReceiptGroup` for date-based grouping
  - `Features/History/Views/` – `HistoryView`, `ExpenseRowView`
  - `Shared/Views/` – `ExpenseDetailView` (shared detail view)

### Settings

- Placeholder tab for app settings and preferences.
- To be implemented with category management, preferences, and app info.

## 📦 Dependencies

### Current Dependencies

| Framework/Technology | Version | Purpose |
|---------------------|---------|---------|
| CoreData | iOS 14.0+ | Local data persistence for expenses and receipts |
| SwiftUI | iOS 14.0+ | Modern declarative UI framework |
| Foundation | iOS 14.0+ | Core Swift framework |
| Vision | iOS 14.0+ | OCR text recognition from receipt images |
| Speech | iOS 14.0+ | Speech-to-text transcription for voice expenses |
| UIKit | iOS 14.0+ | Image picker and camera integration |

**Note:** The app currently uses only Apple's built-in frameworks. No third-party dependencies are required.

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

### Design Guidelines

The app follows a **liquid glass morphism** design aesthetic:

- **Visual Style**: Frosted glass effects using SwiftUI's `.ultraThinMaterial` and `.regularMaterial`
- **Color Restrictions**: 
  - ❌ **Forbidden colors**: Blue, Purple, Cyan, Turquoise
  - ❌ **No gradients** in color schemes
  - ✅ **Preferred**: Warm grays, soft whites, subtle greens, muted oranges, earth tones
- **Background**: Warm neutral solid backgrounds (no gradients)
- **Effects**: Subtle shadows, rounded corners, blur effects for depth
- **Animations**: Smooth, fluid transitions using SwiftUI animations

**Note**: Some UI components may currently use restricted colors (blue, purple) or gradients. These should be updated to comply with the design guidelines.

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

- **HomeViewModel**: Unit tests for loading and formatting summary data
- Test target: `SmartExpenseTests`
- Test file: `HomeViewModelTests.swift`

**Note**: Test coverage will be expanded as features are added.

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
