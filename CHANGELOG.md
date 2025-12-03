# Changelog

All notable changes to the SmartExpense iOS app will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- Initial project setup with SwiftUI and CoreData
- SwiftUI-based Home screen with liquid glass KPI cards:
  - Total Spend (current period)
  - Average Daily Spend
  - Top Merchant
  - Top Category
- MVVM Home feature structure:
  - `HomeSummary` model for aggregated KPI data
  - `HomeViewModel` with async loading and state management
  - `HomeView` and `HomeKPICardView` components
  - `HomeOverviewServiceProtocol` and `HomeOverviewMockService` for data abstraction
- Basic SwiftUI `TabView` app shell with three tabs:
  - Home (default) - Dashboard with KPIs
  - History - Expense/receipt management
  - Settings - Placeholder for app preferences
- CoreData persistence setup:
  - `PersistenceController` for managing CoreData stack
  - Complete data model (`SmartExpense.xcdatamodeld`) with `Receipt` and `ReceiptItem` entities
  - Preview support for SwiftUI development
- **Capture Feature** - Full expense capture system:
  - Camera capture for receipt photos
  - Photo library selection for existing receipt images
  - Voice expense recording with speech-to-text transcription
  - Manual expense entry option
  - OCR text extraction using Vision framework (`ReceiptOCRService`)
  - Receipt data parsing (merchant, date, total, line items)
  - Voice expense parsing (`VoiceExpenseParser`) to extract amount, merchant, and category
  - Receipt editing interface (`ReceiptEditView`) for reviewing and correcting extracted data
  - File storage service (`FileStorageService`) for secure local receipt image storage
  - Permissions management (`PermissionsManager`) for camera, photo library, and microphone
  - Capture flow coordinator (`CaptureCoordinatorView`) managing state machine
- **History Feature** - Complete expense management:
  - Expense list view (`HistoryView`) with date-based grouping (Today, Yesterday, This Week, Last Week, Earlier)
  - Expense detail view (`ExpenseDetailView`) showing full expense information
  - Expense row component (`ExpenseRowView`) for list display
  - Receipt grouping model (`ReceiptGroup`) for date-based organization
  - CRUD operations (create, read, update, delete) for expenses
  - Empty state handling when no expenses exist
  - Integration with capture flow for quick expense addition
- Shared components:
  - `ExpenseDetailView` in `Shared/Views/` for reusable expense detail display
- Project structure reorganization:
  - Moved `Persistence.swift` to `Core/Data/` directory
  - Moved `SmartExpenseApp.swift` to `App/` directory
  - Organized features into `Features/` directory with Capture, History, and Home modules
- Unit tests for `HomeViewModel` (`HomeViewModelTests.swift`)
- Liquid glass morphism design system foundation

### Changed
- Project structure reorganized into feature-based modules
- History tab fully implemented (no longer a placeholder)
- CoreData model expanded with proper `Receipt` and `ReceiptItem` entities
- File structure improved with `Core/`, `Features/`, and `Shared/` directories

### Deprecated

### Removed
- Basic `Item` entity from CoreData model (replaced with `Receipt` and `ReceiptItem`)

### Fixed

### Security

### Known Issues
- Home KPI cards currently use restricted colors (blue, purple) and gradients that violate design guidelines
- Home feature uses mock data service (`HomeOverviewMockService`) until persistence layer is fully integrated
- Some UI components may need design guideline compliance updates (removing gradients and restricted colors)

---

## Version History

<!--
## [1.0.0] - YYYY-MM-DD

### Added
- Feature description

### Changed
- Change description

### Fixed
- Bug fix description
-->

---

**Note:** This file should be updated whenever significant changes are made to the project.
