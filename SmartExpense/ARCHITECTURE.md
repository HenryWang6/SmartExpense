## SmartExpense Architecture

### Overview

SmartExpense uses a modular, feature-first structure with MVVM as the primary UI architecture pattern. The goal is to keep view controllers / views lightweight, centralize business logic in view models, and separate shared infrastructure in `Core/`.

Current top-level layout:

```
SmartExpense/
├── App/              # App entry point and configuration
│   └── SmartExpenseApp.swift
├── Features/         # Feature modules (Home, History, Settings, etc.)
│   └── Home/         # Home feature (dashboard)
├── SmartExpense/     # Main app target
│   ├── ContentView.swift # History tab placeholder
│   └── Persistence.swift  # CoreData persistence controller
└── SmartExpenseTests/ # Unit tests
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
    - A period capsule for the current range (e.g., "This Month") with a refresh action.
    - Horizontally scrollable KPI cards for:
      - Total Spend
      - Average Daily Spend
      - Top Merchant
      - Top Category
    - A floating glass "+" capture button (currently stubbed for future capture flows).
  - `HomeKPICardView`: Reusable glassmorphism card for showing a KPI value and subtitle.

### App Entry and Navigation

- `App/SmartExpenseApp.swift`:
  - Defines the SwiftUI app entry (`@main`).
  - Sets up CoreData persistence controller and injects managed object context into the environment.
  - Hosts a `TabView` with:
    - `HomeView` as the default tab, instantiated with a `HomeViewModel` using `HomeOverviewMockService`.
    - `ContentView` as the History tab (placeholder for expense/receipt management).
    - Placeholder Settings tab.
  - This is where dependency injection starts for the Home feature (wiring the service implementation).

### History Feature (Placeholder)

- `SmartExpense/ContentView.swift`:
  - Currently a placeholder implementation for the History tab.
  - Uses CoreData to display a list of `Item` entities (temporary data model).
  - Shows empty state when no items exist.
  - Includes basic CRUD operations (add, delete) for testing CoreData integration.
  - Will be replaced with a proper expense/receipt management feature in the future.

### Data Persistence

- `SmartExpense/Persistence.swift`:
  - Provides `PersistenceController` singleton for CoreData management.
  - Sets up `NSPersistentContainer` with the "SmartExpense" data model.
  - Supports both in-memory (for previews/testing) and persistent storage.
  - Currently uses a basic CoreData model (`SmartExpense.xcdatamodeld`).
  - The data model will be expanded to include proper entities for receipts, expenses, categories, and merchants.

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

- **Liquid Glass Morphism Design**:
  - Warm neutral solid background (no gradients, no blue, purple, cyan, or turquoise).
  - Foreground cards use SwiftUI's `.ultraThinMaterial` and `.regularMaterial` for frosted glass effects.
  - Subtle shadows and rounded corners create depth.
  - Smooth, fluid animations using SwiftUI's animation system.
  
- **Color Guidelines**:
  - ❌ **Strictly forbidden**: Blue, Purple, Cyan, Turquoise
  - ❌ **No gradients** in color schemes
  - ✅ **Preferred**: Warm grays, soft whites, subtle greens, muted oranges, earth tones
  
- **Accessibility**:
  - Dynamic Type-friendly typography.
  - Careful use of contrast; relying on system label colors over materials where possible.
  - Accessibility labels added to interactive elements.

**Note**: Some UI components (particularly KPI cards in `HomeView`) currently use restricted colors (blue, purple) or gradients. These should be updated to comply with the design guidelines.

### Future Integration Points

- **Data Layer**:
  - Replace `HomeOverviewMockService` with a concrete implementation that aggregates data from:
    - CoreData storage for receipts/voice expenses.
    - Category and merchant metadata.
  - Expand CoreData model to include proper entities:
    - `Receipt` (merchant, date, total, items, source type)
    - `ReceiptItem` (description, quantity, price, category)
    - `Category` (name, type)
    - `MerchantProfile` (name, default category)
  
- **Home Feature Enhancements**:
  - Time-range filters (This Week, Last Month, Custom range).
  - Source filters (Receipts vs Voice vs All).
  - Navigation into detailed Insights and History screens when cards are tapped.
  - Charts and visualizations (line charts, pie charts, bar charts).
  
- **History Feature**:
  - Replace placeholder `ContentView` with proper expense/receipt management.
  - Implement receipt detail view with image viewing.
  - Add search and filtering capabilities.
  - Implement swipe actions for edit/delete.
  
- **Capture Flow**:
  - Receipt scanning with OCR (Vision framework).
  - Voice expense capture with speech recognition.
  - Receipt detail editing screen.

