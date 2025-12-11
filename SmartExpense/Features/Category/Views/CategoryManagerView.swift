import SwiftUI
import CoreData

struct CategoryManagerView: View {
    @Environment(\.managedObjectContext) private var viewContext
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \ExpenseCategory.sortOrder, ascending: true)],
        animation: .default)
    private var categories: FetchedResults<ExpenseCategory>
    
    var body: some View {
        ScrollViewReader { proxy in
            List {
                ForEach(categories) { category in
                    CategoryInlineRow(category: category)
                        // Remove default list row separators and backgrounds to make it look cleaner if needed
                        // or keep standard list style. Keeping standard for now.
                        .id(category.id) // Needed for ScrollViewReader
                }
                .onMove(perform: moveCategory)
                .onDelete(perform: deleteCategory)
                
                // Creation Button
                Button(action: {
                    addCategory(with: proxy)
                }) {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(.blue)
                        Text("Create New Category")
                            .foregroundColor(.blue)
                    }
                }
                .id("CreateButton") // Optional ID
            }
            .navigationTitle("Categories")
            .toolbar {
                 EditButton()
            }
        }
    }
    
    // MARK: - Actions
    
    private func addCategory(with proxy: ScrollViewProxy) {
        withAnimation {
            let newCategory = ExpenseCategory(context: viewContext)
            newCategory.id = UUID()
            newCategory.name = "New Category"
            newCategory.colorHex = "#2ECC71" // Emerald
            newCategory.iconValue = "house"
            newCategory.iconType = "sfSymbol"
            newCategory.isDefault = false
            
            // Calculate new sort order (last + 1)
            let maxOrder = categories.last?.sortOrder ?? 0
            newCategory.sortOrder = maxOrder + 1
            
            do {
                try viewContext.save()
                
                // Scroll to the new item
                // Small delay to allow list to update?
                // Usually FetchRequest updates immediately.
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    if let id = newCategory.id {
                         withAnimation {
                             proxy.scrollTo(id, anchor: .center)
                         }
                    }
                }
            } catch {
                let nsError = error as NSError
                // Should handle error appropriately in prod
                print("Unresolved error \(nsError), \(nsError.userInfo)")
            }
        }
    }

    private func moveCategory(from source: IndexSet, to destination: Int) {
        // Create a mutable array of items from fetched results
        var revisedItems = categories.map { $0 }
        
        // Perform the move on the array
        revisedItems.move(fromOffsets: source, toOffset: destination)
        
        // Update sortOrder for all affected items
        for (index, item) in revisedItems.enumerated() {
            if item.sortOrder != Int32(index) {
                item.sortOrder = Int32(index)
            }
        }
        
        do {
            try viewContext.save()
        } catch {
            print("Error saving reorder: \(error)")
        }
    }

    private func deleteCategory(offsets: IndexSet) {
        withAnimation {
            offsets.map { categories[$0] }.forEach(viewContext.delete)

            do {
                try viewContext.save()
            } catch {
                let nsError = error as NSError
                print("Unresolved error \(nsError), \(nsError.userInfo)")
            }
        }
    }
}

#if DEBUG
struct CategoryManagerView_Previews: PreviewProvider {
    static var previews: some View {
        CategoryManagerView()
            .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}
#endif
