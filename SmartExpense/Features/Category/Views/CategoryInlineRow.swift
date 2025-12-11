import SwiftUI
import CoreData

struct CategoryInlineRow: View {
    @ObservedObject var category: ExpenseCategory
    
    @State private var nameText: String = ""
    @FocusState private var isFocused: Bool
    @State private var isEditing: Bool = false
    @State private var showConfirmationAlert = false
    @State private var pendingAction: AlertAction? = nil
    @State private var showVisualPicker = false
    
    enum AlertAction {
        case save
        case discard
    }
    
    var body: some View {
        HStack(spacing: 12) {
            // MARK: - Visual Component (Icon + Color)
            ZStack {
                Circle()
                    .fill(Color(hex: category.colorHex ?? "#999999"))
                    .frame(width: 40, height: 40)
                
                if category.iconType == "sfSymbol" {
                    Image(systemName: category.iconValue ?? "questionmark")
                        .font(.system(size: 20))
                        .foregroundColor(.white)
                } else {
                    Text(category.iconValue ?? "")
                        .font(.system(size: 20))
                }
            }
            .rotationEffect(.degrees(isEditing ? -5 : 5))
            .animation(
                isEditing ? .easeInOut(duration: 0.15).repeatForever(autoreverses: true) : .default,
                value: isEditing
            )
            .onTapGesture {
                if isEditing {
                    showVisualPicker = true
                }
            }
            .overlay(
                // Optional: visual cue that icon is editable when shaking? 
                // The shake itself is the cue.
                EmptyView()
            )
            
            // MARK: - Content
            if isEditing {
                // Edit State
                TextField("Category Name", text: $nameText)
                    .focused($isFocused)
                    .textFieldStyle(.roundedBorder) // Border indicating editability
                    .submitLabel(.done)
                    .onSubmit {
                        handleSubmit()
                    }
                
                Spacer()
                
                // Action Buttons (Checkmark & X)
                HStack(spacing: 8) {
                    Button(action: {
                        handleSubmit()
                    }) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.title2)
                            .foregroundColor(.green)
                    }
                    .buttonStyle(.plain)
                    
                    Button(action: {
                        cancelEdit()
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundColor(.gray)
                    }
                    .buttonStyle(.plain)
                }
                
            } else {
                // Idle State
                Text(category.name ?? "Unnamed")
                    .font(.body)
                    .foregroundColor(.primary)
                
                Spacer()
                
                // Prominent Pencil Trigger
                Button(action: {
                    startEdit()
                }) {
                    Image(systemName: "pencil")
                        .font(.system(size: 14, weight: .bold)) // Bolder icon
                        .foregroundColor(.gray)
                        .padding(8)
                        .background(
                            Circle()
                                .fill(Color.gray.opacity(0.15)) // Small circle background
                        )
                }
                .buttonStyle(.borderless)
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 4)
        .sheet(isPresented: $showVisualPicker) {
            CategoryVisualPicker(category: category)
                .presentationDetents([.fraction(0.4)])
        }
        .alert("Save Changes?", isPresented: $showConfirmationAlert) {
            Button("Save") {
                confirmSave()
            }
            Button("Discard", role: .destructive) {
                confirmDiscard()
            }
            Button("Cancel", role: .cancel) {
                // Stay in edit mode
                // No action needed, alert dismissal keeps state
            }
        } message: {
            Text("You have unsaved changes to the category name.")
        }
        // Monitor Focus Loss or Edit Mode toggles if needed.
        // In strict mode, we might not need to aggressive monitor focus loss 
        // if we have explicit Save/Cancel buttons, but user might still tap away.
        // For now, let's keep the explicit buttons as the primary exit.
    }
    
    // MARK: - Logic
    
    private func startEdit() {
        nameText = category.name ?? ""
        isEditing = true
        // Delay focus slightly to let UI transition
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            isFocused = true
        }
    }
    
    private func handleSubmit() {
        if nameText != category.name {
            pendingAction = .save
            showConfirmationAlert = true
        } else {
            // No changes, just exit
            exitEditMode()
        }
    }
    
    private func cancelEdit() {
        if nameText != category.name {
             pendingAction = .discard
             showConfirmationAlert = true
        } else {
            exitEditMode()
        }
    }
    
    private func confirmSave() {
        // Update Core Data
        category.name = nameText
        do {
            try category.managedObjectContext?.save()
        } catch {
            print("Error saving category: \(error)")
        }
        exitEditMode()
    }
    
    private func confirmDiscard() {
        exitEditMode()
    }
    
    private func exitEditMode() {
        nameText = category.name ?? ""
        isEditing = false
        isFocused = false
        pendingAction = nil
    }
}

// Extension for Hex Color (assuming it exists or adding a simple one for this view)


#if DEBUG
struct CategoryInlineRow_Preview: PreviewProvider {
    static var previews: some View {
        // Mock Context
        let context = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        
        // Mock Object
        let category = ExpenseCategory(context: context)
        category.name = "Groceries"
        category.iconValue = "🛒"
        category.colorHex = "#2ECC71"
        category.iconType = "emoji"
        
        return VStack {
            CategoryInlineRow(category: category)
            
            Divider()
            
            // Another mock for check (Editing handled by interaction, difficult to mock state directly without view wrapper)
            Text("Interact with above row to test")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .previewLayout(.sizeThatFits)
    }
}
#endif
