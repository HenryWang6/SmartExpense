# Category Management

1. Feature Overview
- A centralized system for users to manage expense categories, which are used to categorize each receipt/expense.
- Location: Access via Settings > Category Management
- Structure: Flat list of categories (No nested categories)
- Default Categories: App ships with a set of default categories, which can be edited or deleted by users.
- Goal: Enable quick, inline editing to minimize taps and navigation.

2. Data Model Specification
Field,Type,Description
id,UUID,Unique identifier.
name,String,"The category name (e.g., ""Groceries,"" ""Transport"")."
isDefault,Boolean,"Flag to track system defaults. (Optional, but useful for onboarding logic)."
iconValue,String,"The actual emoji char (e.g., ""🍔"") or SF Symbol name (e.g., ""cart.fill"")."
colorHex,String,"Hex color code (e.g., ""#FF6F61""). Restricted to the Curated Palette (See Section 4)."
sortOrder,Int,To allow users to sort categories via drag-and-drop.
iconType,Enum,.emoji or .sfSymbol. (Required to know how to render iconValue).

3. UI/UX: Implementation & Interactions
A. The Manager (Settings > Category Management)
The list will use an Inline Editing approach to avoid a separate Edit Page, maximizing efficiency.
    - List Layout:
        - A standard SwiftUI List. Each row displays a Category Row with no chevron.
        - List should allow standard iOS Swipe-to-Delete and enable Drag-to-Reorder via the .onMove modifier.
    
    - Category Name:
        - Displayed in an active TextField.
        - Inline Editing: User taps and types immediately. Data saves automatically on submission or loss of focus.
    
    - Visual Trigger:
        - A large, colored circle on the left of the row, containing the category's icon/emoji.
        - Tap Action: Tapping this element opens a lightweight, non-modal Visual Picker Sheet (Section 3B).
    
    - Add New Row:
        - A persistent final row labeled "Add New Category..." (or similar placeholder).
        - Tapping this row converts it into an active TextField and immediately creates a new ExpenseCategory object in the database with placeholder visuals.
    
B. The Editor (Category Visual Picker)
The functionality of a traditional edit page is collapsed into a small, non-modal overlay, triggered by tapping the visual icon/color badge.
- Sheet Presentation
    - A .sheet with a small, constrained size (.presentationDetents([.fraction(0.4)])).
    - This feels like a contextual pop-over rather than a full page navigation.
- Live Preview
    - A large, centered display of the category's current Icon and Color at the top of the sheet.
    - Real-time Feedback: Updates immediately when the user taps a new color or icon.
- Color Picker
    - A horizontal, scrollable array of circular color swatches, restricted to the Curated Palette.
    - Tap to Select: Tapping a swatch instantly updates the colorHex field in the data model.
- Icon Picker
    - A SegmentedControl (e.g., [EmojiIcons (SF Symbols)]) to switch between libraries.
    - Tap to Select: Tapping a library instantly updates the iconType field in the data model.

We need to introduce a "Focus/Edit State" for the row. The row changes appearance when the user starts typing.
- State: Idle State
    - Icon + Text (Static)
    - User taps the Text to enter Edit State.
- State: Edit State
    - Icon + TextField (Active) + Checkmark Button (Green) + X Button (Gray)
    - The standard "Drag Handle" disappears. Two action buttons appear on the right.

The Logic Flow (for Coding Agent):
- Trigger: User taps the Category Name.
- Action: Keyboard opens. The row enters EditMode. Note: Save the original name in a temporary variable (tempName).
- Submission (User taps "Checkmark" or "Return" on keyboard):
    - Logic: Trigger an Alert/Confirmation Dialog: "Save changes to category name?"
    - If Confirm: Commit change to DB.
    - If Cancel: Revert text to tempName. Exit Edit State.
- Loss of Focus (User taps away/scrolls):
    - Logic: Detect focus loss. Trigger the same Alert: "You have unsaved changes. Save now?"
    - If Save: Commit.
    - If Discard: Revert.

4. Style Guide & Curated Palette
A. Curated Color Palette
The app must restrict users to this set of pre-vetted hex codes to ensure consistency and readability in both Light and Dark modes. The Coding Agent must not implement a standard iOS Color Picker.

Color Name,Hex Code,Intended Use Case (Examples)
Emerald,#2ECC71,"Groceries, Income"
Money Green,#27AE60,"Savings, Investments"
Teal,#1ABC9C,"Utilities, Services"
Sky Blue,#3498DB,"Travel, Flight, Hotel"
Navy,#34495E,"Business, Office, Taxes"
Indigo,#5B5EA6,"Insurance, Subscriptions"
Purple,#9B59B6,"Rent, Mortgage, Housing"
Lavender,#E0BBE4,"Personal Care, Beauty"
Coral Red,#E74C3C,"Health, Medical, Pharmacy"
Pumpkin,#D35400,"Dining Out, Fast Food"
Tangerine,#F39C12,"Entertainment, Events"
Sunflower,#F1C40F,"Shopping, Clothing"
Coffee,#6D4C41,"Coffee, Cafes"
Slate,#95A5A6,"Fees, Bank Charges"
Carbon,#2C3E50,"Electronics, Hardware"
Berry,#C0392B,"Debt, Loans, Credit Card"

B. Default Categories (Bootstrap Data)
The initial setup should include these for a good first-use experience.
Based on the North American lifestyle, these are the recommended defaults to seed the database with.
- Housing: 🏠 (#9B59B6 - Purple)
- Groceries: 🛒 (#2ECC71 - Emerald)
- Dining Out: 🍔 (#D35400 - Pumpkin)
- Coffee: ☕️ (#6D4C41 - Coffee)
- Transport: 🚘 (#3498DB - Sky Blue)
- Utilities: 💡 (#1ABC9C - Teal)
- Shopping: 🛍️ (#F1C40F - Sunflower)
- Health: 💊 (#E74C3C - Coral Red)
- Entertainment: 🎬 (#F39C12 - Tangerine)
- Insurance: 🛡️ (#5B5EA6 - Indigo)