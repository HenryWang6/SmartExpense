import SwiftUI
import CoreData
import Combine

struct CategoryCreationSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.managedObjectContext) private var parentContext
    
    /// Scratchpad context for editing the new category without polluting the main context immediately
    @StateObject private var childContextModel: ChildContextModel
    
    var onSaved: ((ExpenseCategory) -> Void)?
    
    init(parentContext: NSManagedObjectContext, onSaved: ((ExpenseCategory) -> Void)? = nil) {
        self._childContextModel = StateObject(wrappedValue: ChildContextModel(parentContext: parentContext))
        self.onSaved = onSaved
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                // Name Input
                VStack(alignment: .leading, spacing: 8) {
                    Text("Category Name")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .textCase(.uppercase)
                    
                    TextField("E.g., Groceries", text: $childContextModel.name)
                        .font(.title3)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                }
                .padding(.horizontal)
                .padding(.top)
                
                // Visual Picker
                if let category = childContextModel.newCategory {
                    CategoryVisualPicker(category: category)
                }
                
                Spacer()
            }
            .background(Color(.systemBackground))
            .navigationTitle("New Category")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveAndDismiss()
                    }
                    .fontWeight(.bold)
                    .disabled(childContextModel.name.isEmpty)
                }
            }
        }
    }
    
    private func saveAndDismiss() {
        guard let category = childContextModel.newCategory else { return }
        category.name = childContextModel.name
        
        // Save child context -> Pushes to Parent Context
        if childContextModel.save() {
            // Save Parent Context to persist to store
            do {
                try parentContext.save()
                
                // Pass the object ID or the object itself back
                // We need to fetch it in the parent context to return a valid object for the caller
                let objectInParent = parentContext.object(with: category.objectID) as? ExpenseCategory
                if let safeObject = objectInParent {
                    onSaved?(safeObject)
                }
                
                dismiss()
            } catch {
                print("Error saving parent context: \(error)")
            }
        }
    }
}

/// Helper model to manage the child context lifecycle
class ChildContextModel: ObservableObject {
    let childContext: NSManagedObjectContext
    @Published var newCategory: ExpenseCategory?
    @Published var name: String = ""
    
    init(parentContext: NSManagedObjectContext) {
        self.childContext = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        self.childContext.parent = parentContext
        
        // Create the scratchpad object immediately
        let category = ExpenseCategory(context: childContext)
        category.id = UUID()
        category.name = "" // Will be bound or set
        category.colorHex = "#2ECC71" // Default Emerald
        category.iconType = "sfSymbol"
        category.iconValue = "house"
        category.isDefault = false
        
        // Calculate a safe sort order (optional, ideally passed in but reasonable default is sufficient for now)
        category.sortOrder = 999 
        
        self.newCategory = category
    }
    
    func save() -> Bool {
        guard let category = newCategory else { return false }
        category.name = name
        
        do {
            try childContext.save()
            return true
        } catch {
            print("Error saving child context: \(error)")
            return false
        }
    }
}
