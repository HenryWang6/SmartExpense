## SmartExpense Architecture

### Overview

SmartExpense uses a modular, feature-first structure with MVVM as the primary UI architecture pattern. The goal is to keep view controllers / views lightweight, centralize business logic in view models, and separate shared infrastructure in `Core/`.

Current top-level layout:

```
SmartExpense/
├── App/              # App entry point and configuration
├── Features/         # Feature modules (Home, History, Settings, etc.)
├── Core/             # Shared services, storage, networking (future)
├── Resources/        # Assets, strings, fonts
└── Supporting Files/ # Config and metadata
```

### Home Feature

The Home feature presents a dashboard with KPIs based on the locally stored receipts/expenses. It follows MVVM:

- `Features/Home/Models/` – Feature-specific models:
  - `HomeSummary`: Aggregated values for the current period (total spend, average daily spend, top merchant, top category).
- `Features/Home/Services/` – Data access abstractions:
  - `HomeOverviewServiceProtocol`: Protocol describing how to load the Home summary.
  - `HomeOverviewMockService`: Temporary implementation returning static data until the storage layer is available.
- `Features/Home/ViewModels/`:
  - `HomeViewModel`: An `ObservableObject` responsible for:
    - Loading a `HomeSummary` from the service.
    - Managing loading/error state.
    - Formatting currency and strings for presentation on the Home screen.
- `Features/Home/Views/`:
  - `HomeView`: SwiftUI screen that binds to `HomeViewModel` and renders:
    - A greeting and short description.
    - A period capsule for the current range (e.g., “This Month”) with a refresh action.
    - Horizontally scrollable KPI cards for:
      - Total Spend
      - Average Daily Spend
      - Top Merchant
      - Top Category
    - A floating glass “+” capture button (currently stubbed for future capture flows).
  - `HomeKPICardView`: Reusable glassmorphism card for showing a KPI value and subtitle.

### App Entry and Navigation

- `App/SmartExpenseApp.swift`:
  - Defines the SwiftUI app entry (`@main`).
  - Hosts a `TabView` with:
    - `HomeView` as the default tab, instantiated with a `HomeViewModel` using `HomeOverviewMockService`.
    - Placeholder tabs for History and Settings.
  - This is where dependency injection starts for the Home feature (wiring the service implementation).

### Data Flow (Home)

1. `SmartExpenseApp` creates a `HomeViewModel` with a concrete `HomeOverviewServiceProtocol` implementation.
2. `HomeView` observes the `HomeViewModel` via `@ObservedObject`.
3. When `HomeView` appears, it calls `viewModel.onAppear()`, which triggers a load if needed.
4. `HomeViewModel` requests a `HomeSummary` from its `service`.
5. The service returns a `HomeSummary` (mocked for now).
6. `HomeViewModel`:
   - Updates its `@Published` properties for:
     - `state` (loading/loaded/error).
     - `periodTitle`.
     - Formatted text for each KPI.
   - The SwiftUI view updates automatically in response to these changes.

### Visual Design Considerations

- Home uses a liquid glass style:
  - Warm neutral solid background (no gradients, no blue, purple, cyan, or turquoise).
  - Foreground cards use SwiftUI’s `.ultraThinMaterial` for frosted glass effects.
  - Subtle shadows and rounded corners create depth.
- Accessibility:
  - Dynamic Type-friendly typography.
  - Careful use of contrast; relying on system label colors over materials where possible.

### Future Integration Points

- Replace `HomeOverviewMockService` with a concrete implementation that aggregates data from:
  - Local storage (Core Data or similar) for receipts/voice expenses.
  - Category and merchant metadata.
- Extend the Home feature with:
  - Time-range filters.
  - Source filters (Receipts vs Voice).
  - Navigation into detailed Insights and History screens when cards are tapped.


