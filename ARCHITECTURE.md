## SmartExpense Architecture

### Overview

SmartExpense uses a modular, feature-first structure with MVVM as the primary UI architecture pattern. The goal is to keep view controllers / views lightweight, centralize business logic in view models, and separate shared infrastructure in `Core/`.

Current top-level layout:

```
SmartExpense/
├── App/              # App entry point and configuration
│   └── SmartExpenseApp.swift
├── Core/             # Core infrastructure
│   └── Data/         # Data persistence layer
│       └── Persistence.swift  # CoreData persistence controller
├── Features/         # Feature modules (Home, History, Capture, Settings, etc.)
│   ├── Capture/      # Receipt and voice expense capture
│   ├── History/      # Expense history and management
│   └── Home/         # Home feature (dashboard)
├── Shared/           # Shared components across features
│   └── Views/        # ExpenseDetailView
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
  - Sets up CoreData persistence controller and injects managed object context into the environment.
  - Hosts a `TabView` with:
    - `HomeView` as the default tab, instantiated with a `HomeViewModel` using `HomeOverviewMockService`.
    - `HistoryView` (aliased as `ContentView` for backward compatibility) as the History tab.
    - Placeholder Settings tab.
  - This is where dependency injection starts for the Home feature (wiring the service implementation).

### Capture Feature

The Capture feature provides multiple ways to input expenses: camera, photo library, voice, and manual entry. It follows MVVM architecture:

- `Features/Capture/Models/`:
  - `CaptureOption`: Enum defining capture methods (camera, voice, manual).
  - `ExtractedReceiptData`: Model for OCR-extracted receipt data (merchant, date, total, line items).

- `Features/Capture/Services/`:
  - `ReceiptOCRService`: Uses Vision framework to extract text from receipt images and parse structured data.
  - `SpeechRecognitionService`: Handles speech-to-text transcription using Speech framework.
  - `VoiceExpenseParser`: Parses transcribed voice input to extract amount, merchant, and category.
  - `FileStorageService`: Manages local file storage for receipt images (saves to app's documents directory).
  - `PermissionsManager`: Centralized permission handling for camera, photo library, and microphone.

- `Features/Capture/ViewModels/`:
  - `ReceiptEditViewModel`: Manages the receipt editing state, handles saving to CoreData, and coordinates with file storage.

- `Features/Capture/Views/`:
  - `CaptureCoordinatorView`: Main coordinator that manages the capture flow state machine.
  - `CaptureMenuView`: Initial menu for selecting capture method.
  - `ImagePickerView`: Wrapper for UIImagePickerController (camera/photo library).
  - `ImagePreviewView`: Preview screen before processing receipt image.
  - `ProcessingView`: Loading state during OCR processing.
  - `ReceiptEditView`: Full editing interface for reviewing and correcting extracted data.
  - `VoiceRecordingView`: Interface for recording voice expenses.
  - `VoiceExpenseReviewView`: Review screen for parsed voice expenses.
  - `LineItemRowView`: Reusable component for displaying receipt line items.

### History Feature

The History feature provides a complete expense management interface:

- `Features/History/Models/`:
  - `ReceiptGroup`: Model for grouping receipts by date sections (Today, Yesterday, This Week, etc.).

- `Features/History/Views/`:
  - `HistoryView`: Main list view showing all expenses grouped by date.
    - Uses CoreData `@FetchRequest` to load `Receipt` entities.
    - Implements empty state when no expenses exist.
    - Provides navigation to detail view and capture flow.
    - Supports swipe-to-delete for expense removal.
  - `ExpenseRowView`: List row component displaying expense summary (merchant, date, amount).

- `Shared/Views/`:
  - `ExpenseDetailView`: Shared detail view showing full expense information:
    - Total amount and date header
    - Merchant details and category
    - Line items with quantities and prices
    - Receipt image display (if available)

### Data Persistence

- `Core/Data/Persistence.swift`:
  - Provides `PersistenceController` singleton for CoreData management.
  - Sets up `NSPersistentContainer` with the "SmartExpense" data model.
  - Supports both in-memory (for previews/testing) and persistent storage.
  - CoreData model (`SmartExpense.xcdatamodeld`) includes:
    - **Receipt** entity: Main expense record with merchant, date, total amount, capture method, image path, and relationship to line items.
    - **ReceiptItem** entity: Individual line items with description, quantity, unit price, subtotal, category, and sort order.
  - Receipt images are stored separately in the app's documents directory via `FileStorageService`, with only the file path stored in CoreData.

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
  
- **History Feature Enhancements**:
  - Add search and filtering capabilities (by merchant, category, date range).
  - Implement swipe actions for quick edit.
  - Add export functionality (CSV, PDF).
  
- **Capture Flow Enhancements**:
  - PDF receipt support (multi-page handling).
  - Improved OCR accuracy and line item extraction.
  - Merchant profile learning (auto-categorization based on history).
  - Batch processing for multiple receipts.


