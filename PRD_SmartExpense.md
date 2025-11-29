## Smart Expense – Product Requirements Document (PRD)

### 1. Product Overview

**Product name**: Smart Expense  
**Platform**: iOS (iPhone, later iPad)  
**Purpose**: Help users effortlessly capture, categorize, and understand their expenses from receipts and voice, and gain clear insights via modern visualizations.

### 2. Objectives & Success Metrics

- **Primary objectives**
  - **Reduce friction** in expense tracking by automating data capture from receipts and voice.
  - **Increase awareness** of spending patterns by merchant and category.
  - **Enable control** via local storage and easy editing of expense data.

- **Success metrics (v1)**
  - **Onboarding success**: ≥70% of new users successfully add at least 1 receipt or voice expense within first session.
  - **Automation**: ≥80% of receipts processed without user needing to re-enter total amount.
  - **Engagement**: ≥40% of active users open the stats/insights screen at least once per week.
  - **User satisfaction**: App Store rating ≥4.3 after first 3 months.

### 3. Target Users & Personas

- **Busy Professional**
  - Tracks personal and work-related expenses.
  - Needs quick capture after dining, transport, shopping.
  - Cares about monthly summaries and category breakdown.

- **Budget-Conscious Individual**
  - Manually tracks expenses now (spreadsheets, notes).
  - Wants categorized and visualized data with minimal data entry.

- **Freelancer / Self-Employed**
  - Needs receipts and expenses categorized by merchant and category.
  - Wants clear exportable data later (future scope).

### 4. Scope

- **In-scope (v1)**
  - Receipt image/pdf ingestion and extraction.
  - Voice-based expense capture.
  - Basic categorization (merchant + item categories).
  - Local-only data storage and management (CRUD).
  - Expense insights (weekly/monthly/yearly, merchant & category).
  - Modern visualizations (KPI cards, line charts, bar charts, pie charts).

- **Out-of-scope (future versions)**
  - Cloud sync / multi-device accounts.
  - Export to CSV/PDF, accounting tools.
  - Multi-currency support.
  - Shared accounts / family plans.
  - Integrations with bank/credit card feeds.

### 5. Core User Flows

#### 5.1 Onboarding & Permissions

- **Flow**
  - User opens app for the first time.
  - Intro screens:
    - **Screen 1**: “Capture receipts with your camera & voice.”
    - **Screen 2**: “Track by category & merchant with visual insights.”
  - Permissions requests:
    - Camera (for receipt capture).
    - Photos (for picking existing receipts).
    - Microphone (for voice input).
  - User lands on **Home / Dashboard**.

#### 5.2 Add Receipt via Photo

- **Flow**
  - From Home, user taps **“Add Receipt”**.
  - Options: **“Take Photo”** / **“Choose from Library”** / **“Import PDF”**.
  - After image/pdf selection:
    - Show a preview of the selected photo/file with options **“Retake/Change”** and **“Process”**.
    - Only when the user taps **“Process”**, start extraction and show an intermediate **“Processing receipt…”** state.
    - Extract:
      - Merchant name.
      - Date & time.
      - Total amount.
      - Line items (description, quantity, unit price, line subtotal).
    - Show **Receipt Detail Edit screen** with extracted data pre-filled.
  - User:
    - Edits incorrect fields (merchant, date, items, etc.).
    - Assigns or confirms **merchant category** and **item categories**.
  - User saves receipt → data stored locally.

#### 5.3 Add Expense via Voice

- **Flow**
  - From Home, user taps **“Voice Expense”**.
  - Interface: large microphone button, hint text (e.g., “Say something like: ‘$45 at Starbucks for coffee and snacks’”).
  - User taps mic, speaks expense.
  - App:
    - Transcribes speech to text.
    - Extracts:
      - Total amount.
      - Merchant (if inferable).
      - Item categories and/or high-level category.
    - Shows **Voice Expense Review screen**:
      - Transcribed text.
      - Parsed total amount.
      - Parsed category (or suggestion list).
  - User confirms/edits fields, then saves as an expense record (optionally associated with a “virtual receipt”).

#### 5.4 Manage Receipts & Expenses

- **Flow**
  - User opens **Receipts** tab.
  - Sees list:
    - Thumbnail of receipt image (if any).
    - Merchant name.
    - Date/time.
    - Total amount.
  - Actions:
    - Tap receipt to open detail:
      - View full image/pdf.
      - View/edit merchant, date, total, line items, categories.
    - Swipe left → **Edit**, **Delete**.
  - Editing:
    - User can:
      - Add/remove items.
      - Change quantities, prices.
      - Adjust categories.
      - Update merchant category.

#### 5.5 View Insights & Visualization

- **Flow**
  - User navigates to **Insights** tab.
  - Time range selector: **Weekly / Monthly / Yearly / Custom**.
  - Screens:
    - **KPI Cards**:
      - Total spend for selected period. Default at current month.
      - Average daily spend.
      - Top 1–3 merchants & spending amount.
      - Top 1–3 categories & spending amount.
    - **Charts**:
      - Line/area chart: expense trend over time.
      - Pie chart: share of spending by category.
      - Bar chart: top merchants by total spend.
  - Filters:
    - Filter by month.
    - Filter by category.
    - Filter by merchant.

### 6. Detailed Functional Requirements

#### 6.1 Receipt Ingestion & Extraction

- **Input sources**
  - **Camera capture**:
    - Must support auto-focus and allow user to retake.
    - Option to crop/rotate if needed (v1: optional).
  - **Photo library**:
    - Supports common formats (JPEG, PNG, HEIC).
  - **PDF import**:
    - Single-page and multi-page receipts (show each page if multi-page).

- **Data extraction requirements**
  - **Merchant Name**
    - Extract from the prominent header text.
    - If ambiguous, suggest top 3 candidates or allow manual input.
  - **Receipt Date & Time**
    - Parse formats like `MM/DD/YYYY`, `DD/MM/YYYY`, `YYYY-MM-DD`, with or without time.
    - If no time found, default to noon or allow user to set time.
  - **Total Price**
    - Detect gross total (prefer “Total”, “Amount Due” labels).
    - Avoid sub-totals, taxes, tips when not final total.
  - **Items**
    - For each item:
      - **Fields**: item name/description, quantity, unit price, line subtotal.
      - Attempt to parse per-line; if structure unclear, group as single-line item with total.
  - **Extraction confidence**
    - Internal confidence scoring (not necessarily exposed, but used to mark fields needing user attention).
    - Fields below threshold should be visually highlighted for review.

- **Error handling**
  - If extraction fails:
    - Show user-friendly message.
    - Provide **“Manual entry”** form prefilled with only uploaded image, let user type everything.

#### 6.2 Voice Input & Parsing

- **Voice capture**
  - Tap-to-record, tap-to-stop pattern.
  - Display waveform or timer during recording.
  - Max duration (e.g., 30–60 seconds).

- **Transcription & NLP**
  - Convert speech to text (using built-in iOS speech APIs in v1 if possible).
  - Extract:
    - **Total amount** (e.g., “twenty three dollars and fifty cents” → 23.50).
    - **Merchant or payee name** (e.g., “Starbucks”, “Uber”).
    - **Category**:
      - Map words to categories (e.g., “groceries”, “coffee”, “taxi”, “subscription”).
  - Show parsed result and original transcription for user to confirm.

- **Required fields for saving**
  - Date (default to now, editable).
  - Total amount (must be present).
  - Category (must be selected; default suggestion allowed).

#### 6.3 Categorization

- **Merchant category**
  - Each merchant is associated with a **single primary category** (v1).
  - When user edits a merchant’s category:
    - Optionally suggest: “Apply this category automatically next time for this merchant.”

- **Item categories**
  - Each item line has a category.
  - Default mapping rules:
    - Use known merchant profile if available.
    - Use keyword-based mapping on item description.
  - Allow user to:
    - Choose from predefined list of categories.
    - Edit categories on item and receipt level.

- **Category set (v1)**
  - Example default categories:
    - Food & Dining, Groceries, Transport, Shopping, Utilities, Subscriptions, Travel, Entertainment, Health, Other (configurable later).

#### 6.4 Storage & Data Model (Local Only, v1)

- **Storage**
  - Data stored on-device only (Core Data / SQLite / file-based).
  - No external account or backend in v1.
  - Store both the **extracted receipt metadata** and the **original receipt asset** (photo/pdf) so users can always reference the source.
  - Receipt assets should be written to the app’s documents directory (or `FileManager`-managed subfolder) using an efficient format:
    - Prefer HEIF/HEIC or JPEG with compression for photos captured in-app.
    - Keep PDFs as-is; if multiple pages, store the full document.
    - Save only the file path/identifier in Core Data to avoid inflating the database.
  - Implement background compression/saving so the UI remains responsive.

- **Core entities (conceptual)**
  - **Receipt**
    - id
    - merchantName
    - merchantCategoryId
    - dateTime
    - totalAmount
    - sourceType (photo, pdf, manual, voice)
    - isVoiceInput flag (true for entries originating from voice capture)
    - imagePath / pdfPath
    - createdAt, updatedAt
  - **ReceiptItem**
    - id
    - receiptId (FK)
    - description
    - quantity
    - unitPrice
    - subtotal
    - categoryId
  - **VoiceExpense**
    - id
    - description (transcription)
    - dateTime
    - totalAmount
    - merchantName (optional)
    - categoryId
    - createdAt, updatedAt
  - **Category**
    - id
    - name
    - type (system, user-defined – v2)
  - **MerchantProfile** (optional v1 or v1.1)
    - merchantName
    - defaultCategoryId

#### 6.5 Receipts & Expense Management

- **Listing**
  - Display receipts & voice expenses in reverse chronological order.
  - Group by date (Today, Yesterday, This Week, etc.).
  - Search by merchant name, category, or amount range (v1: simple search by merchant).

- **Editing**
  - Requirements:
    - All fields editable except internal ids.
    - Recalculate totals when items are changed (sum of line items; optionally allow discrepancy vs original total with indicator).
  - Validation:
    - Total amount must be ≥ sum of item subtotals or allow slight differences (due to tax/tip).

- **Deletion**
  - Single-item delete with confirmation.
  - Remove associated image/pdf from storage.

### 7. Insights & Visualization Requirements

- **Time ranges**
  - Quick-select: **This Week**, **This Month**, **This Year**, **Last Month**.
  - Simple date range picker (v1 minimal).

- **KPIs**
  - **Total Spend** for selected range.
  - **Avg Daily Spend**.
  - **Top Merchant** by total amount.
  - **Top Category** by total amount.

- **Charts**
  - **Trend (Line/Area Chart)**:
    - X-axis: days/weeks/months depending on range.
    - Y-axis: total spend.
    - Supports tap to see exact values.
  - **Category Pie Chart**:
    - Slices by category, sized by total spend.
    - Legend showing category name + amount + percentage.
  - **Merchant Bar Chart**:
    - Bars representing top N merchants (e.g., top 5).
    - Height = total spend.

- **Filters**
  - Filter by:
    - Category (single select).
    - Merchant (single or multi select).
    - Source: Receipts vs Voice vs All.

### 8. Non-Functional Requirements

- **Performance**
  - Receipt extraction should complete within:
    - Target: 5–8 seconds for typical image.
    - Hard limit: 15 seconds with progress indicator.
  - Insights screen should load in under 2 seconds for up to ~5,000 records.

- **Privacy & Security**
  - Data stored only on device by default (no external servers).
  - Respect iOS privacy guidelines for camera, photos, microphone.
  - Clearly state in onboarding that data is local (unless changed in future).

- **Reliability**
  - App should handle interruptions (phone calls, backgrounding) during photo/voice capture gracefully (either resume or retry).

- **Accessibility**
  - Support Dynamic Type (large text).
  - Ensure color contrast in charts and KPIs.
  - VoiceOver labels for key buttons and charts (summary text for charts).

### 9. UX & Visual Design Principles

- **Design style**
  - Clean, modern, minimal.
  - Emphasis on cards for receipts and KPIs.
  - Use accent color for primary actions (e.g., “Add Receipt”, “Voice Expense”).

- **Navigation**
  - Tab bar with:
    - **Home** (default) – insights & visualizations.
    - **History** – expense/receipt list and management.
    - **Profile/Settings** – categories, preferences, app info (can be merged or simplified in MVP).
  - A prominent floating **“+ Capture”** button is available on the Home screen (and optionally shared across tabs) to start the capture flow (scan receipt, upload file, voice expense).

- **Empty states**
  - Home without data:
    - Illustration + copy: “No expenses yet. Start by scanning your first receipt or using voice.”
    - Primary CTA: **Add Receipt** / **Try Voice Expense**.
  - Insights without data:
    - Message: “Add some expenses to see your spending trends.”

### 9.1 App Layout & Key Screens

- **Home – Insights & Capture (Default Page)**
  - Background:
    - Soft warm gray or off‑white base with subtle, blurred forms (no gradients, no blue/purple/cyan/turquoise).
    - Large, layered “glass” panels using blur and transparency to create depth.
  - Top area:
    - Glass capsule with month/time range selector and filter chips:
      - “This Month” (default), “Last Month”, “This Year”.
      - Optional chips: “All”, “Receipts”, “Voice”.
  - KPI row:
    - 2–3 glass cards in a horizontal scroll or 2x2 grid:
      - Total Spend (current month) with delta vs last period.
      - Average Daily Spend.
      - Top Merchant & spending amount.
      - Top Category & spending amount.
  - Charts:
    - Full-width glass card for trend (line/area) chart over time.
    - Row of two glass cards:
      - Category pie/donut chart.
      - Top merchants bar chart.
  - Primary capture CTA:
    - Floating circular glass **“+”** button at the bottom (center or right):
      - Tapping opens a capture sheet: **Scan Receipt**, **Upload File**, **Voice Expense**.
    - Optional inline “Quick Capture” glass card near the top with large buttons for Scan Receipt and Voice Expense.
  - Empty state:
    - Replace charts with a tall glass card inviting the user to “Capture your first expense” with a primary button.

- **Capture Flow (Modal / Separate Stack)**
  - Capture type selector:
    - Bottom sheet or full-screen glass panel with three options:
      - **Scan Receipt**, **Upload File**, **Voice Expense**, each with 1-line description.
  - Scan / Upload:
    - Camera or file picker view with glass controls (close, capture/change).
    - Preview & confirm screen:
      - Large preview of photo/PDF inside a glass frame.
      - Bottom glass bar with **Retake/Change** and primary **Process** button.
    - Processing state:
      - Same preview blurred behind a centered glass “Processing receipt…” card with subtle spinner/animation.
    - Edit extracted data screen:
      - Scrollable glass cards:
        - Header card for merchant, date/time, total.
        - Items list where each item is a mini-glass row (description, qty, price, category).
      - Sticky bottom bar with Cancel and Save buttons.
  - Voice Expense:
    - Recording screen:
      - Large circular mic button on a glass card.
      - Hint text below with example utterances.
      - Subtle waveform animation for feedback.
    - Review screen:
      - Glass card showing transcription, parsed amount, merchant (if any), and category picker.
      - Bottom primary “Save expense” button.

- **History – Expense Management Page**
  - Top filters:
    - Glass filter bar with:
      - Month selector (default current month).
      - Category filter.
      - Search (merchant/keyword).
  - List:
    - Expenses grouped by date (e.g., Today, Yesterday, specific dates).
    - Each row is a glass list item:
      - Left: icon indicating receipt vs voice, plus small category color chip.
      - Middle: merchant or description, with subtitle (category + time).
      - Right: bold amount.
    - Swipe actions for quick Edit and Delete.
  - Expense detail:
    - Glass header card with merchant, date/time, total, and a tag for “Voice input” when applicable.
    - Items displayed as small glass chips/rows with description, qty, price, category.
    - Thumbnail of the receipt; tap to expand into a full-screen viewer.
    - Edit mode reuses the same layout with editable fields.
  - Empty state:
    - Glass card explaining “No expenses this month” with a button to capture an expense.

- **Profile / Settings**
  - Simple list of glass cards for:
    - Category overview/management (read-only in v1 if needed).
    - Data & privacy (on-device storage explanation).
    - About & version info.

### 10. Technical Notes & Dependencies (High-Level)

- **Potential iOS frameworks**
  - Vision / VisionKit for OCR (or 3rd-party OCR if needed).
  - Speech framework for voice transcription.
  - Core Data or similar for local DB.
  - SwiftUI or UIKit for UI (implementation detail; not mandated by PRD).

- **Extensibility**
  - Data models and architecture should anticipate:
    - Cloud sync (future).
    - Exports.
    - Additional input sources (email parsing, bank connections).

### 11. Release Plan (MVP vs Future)

- **MVP (v1)**
  - Core receipt capture (camera + photo library).
  - Basic OCR & extraction for merchant, date, total, simple items.
  - Voice input with total & category parsing.
  - Local storage & basic management (list, view, edit, delete).
  - Simple insights: monthly/weekly totals, basic charts.

- **Future Enhancements (TBD)**
  - More robust line-item extraction and improved NLP.
  - Merchant profiles with learning-based categorization.
  - Export to CSV/PDF.
  - iCloud sync and multi-device support.
  - Budgeting goals and alerts.


