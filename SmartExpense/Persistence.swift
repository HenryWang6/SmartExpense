//
//  Persistence.swift
//  SmartExpense
//
//  Created by Henry Wang on 2025-11-29.
//

import CoreData

struct PersistenceController {
    static let shared = PersistenceController()

    @MainActor
    static let preview: PersistenceController = {
        let result = PersistenceController(inMemory: true)
        let viewContext = result.container.viewContext
        
        // Create sample receipts for preview
        for i in 0..<10 {
            let receipt = Receipt(context: viewContext)
            receipt.id = UUID()
            receipt.merchantName = "Sample Merchant \(i)"
            receipt.date = Date().addingTimeInterval(-Double(i) * 86400) // Past days
            receipt.totalAmount = Double.random(in: 10...200)
            receipt.isVoiceInput = i % 3 == 0
            receipt.createdAt = Date()
            
            // Add sample items to some receipts
            if i % 2 == 0 {
                let item = ReceiptItem(context: viewContext)
                item.id = UUID()
                item.name = "Sample Item \(i)"
                item.price = Double.random(in: 5...50)
                item.quantity = Int16.random(in: 1...5)
                item.receipt = receipt
            }
        }
        
        do {
            try viewContext.save()
        } catch {
            let nsError = error as NSError
            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
        }
        return result
    }()

    let container: NSPersistentContainer

    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "SmartExpense")
        if inMemory {
            container.persistentStoreDescriptions.first!.url = URL(fileURLWithPath: "/dev/null")
        }
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.

                /*
                 Typical reasons for an error here include:
                 * The parent directory does not exist, cannot be created, or disallows writing.
                 * The persistent store is not accessible, due to permissions or data protection when the device is locked.
                 * The device is out of space.
                 * The store could not be migrated to the current model version.
                 Check the error message to determine what the actual problem was.
                 */
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        container.viewContext.automaticallyMergesChangesFromParent = true
    }
}
