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
  - History - Placeholder for expense/receipt management
  - Settings - Placeholder for app preferences
- CoreData persistence setup:
  - `PersistenceController` for managing CoreData stack
  - Basic data model (`SmartExpense.xcdatamodeld`)
  - Preview support for SwiftUI development
- Unit tests for `HomeViewModel` (`HomeViewModelTests.swift`)
- Liquid glass morphism design system foundation

### Changed

### Deprecated

### Removed

### Fixed

### Security

### Known Issues
- Home KPI cards currently use restricted colors (blue, purple) and gradients that violate design guidelines
- History tab is a placeholder using basic CoreData `Item` model (to be replaced with proper expense entities)
- Home feature uses mock data service (`HomeOverviewMockService`) until persistence layer is fully integrated

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
