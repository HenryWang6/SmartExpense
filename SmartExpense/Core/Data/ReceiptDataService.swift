//
//  ReceiptDataService.swift
//  SmartExpense
//
//  Created by Antigravity on 2025-12-12.
//

import CoreData
import UIKit

/// Service responsible for all Receipt-related data operations
class ReceiptDataService: DataService {
    let context: NSManagedObjectContext
    
    required init(context: NSManagedObjectContext) {
        self.context = context
    }
    
    // MARK: - CRUD
    
    /// Creates a new receipt with the provided details
    @discardableResult
    func createReceipt(
        merchantName: String,
        amount: Double,
        date: Date,
        category: String?,
        imagePath: String? = nil,
        isVoiceInput: Bool = false,
        captureMethod: String = "manual",
        note: String? = nil,
        viewContext: NSManagedObjectContext? = nil // Optional override if needed, usually defaults to self.context
    ) throws -> Receipt {
        let receipt = Receipt(context: context)
        receipt.id = UUID()
        receipt.merchantName = merchantName.trimmingCharacters(in: .whitespacesAndNewlines)
        receipt.totalAmount = amount
        receipt.date = date
        receipt.merchantCategory = category
        receipt.imagePath = imagePath
        receipt.isVoiceInput = isVoiceInput
        receipt.captureMethod = captureMethod
        receipt.note = note
        receipt.createdAt = Date()
        receipt.updatedAt = Date()
        
        // Link Relation
        linkCategory(name: category, to: receipt)
        
        try save()
        return receipt
    }
    
    /// Deletes a receipt
    func delete(_ receipt: Receipt) throws {
        // If there's an image, we should ideally delete it involved file manager,
        // but for now we follow existing logic which just deletes the Core Data entity.
        // File cleanup could be added here later.
        context.delete(receipt)
        try save()
    }
    
    /// Deletes multiple receipts
    func delete(_ receipts: [Receipt]) throws {
        receipts.forEach { context.delete($0) }
        try save()
    }
    
    // MARK: - Batch Logic
    
    /// Updates all receipts that have the `oldName` category to `newName`
    /// This is used when a Category is renamed in the Category Manager
    func updateCategoryOfReceipts(from oldName: String, to newName: String) throws {
        guard !oldName.isEmpty else { return }
        
        let request: NSFetchRequest<Receipt> = Receipt.fetchRequest()
        request.predicate = NSPredicate(format: "merchantCategory == %@", oldName)
        
        // Also fetch the NEW category entity to link it
        let categoryRequest: NSFetchRequest<ExpenseCategory> = ExpenseCategory.fetchRequest()
        categoryRequest.predicate = NSPredicate(format: "name == %@", newName)
        let newCategoryEntity = try? context.fetch(categoryRequest).first
        
        let receipts = try context.fetch(request)
        
        // If no receipts found, we don't need to do anything, but let's check
        guard !receipts.isEmpty else { return }
        
        for receipt in receipts {
            receipt.merchantCategory = newName
            receipt.category = newCategoryEntity // Link Relation
            receipt.updatedAt = Date()
        }
        
        try save()
    }
    
    // MARK: - Helper
    
    private func linkCategory(name: String?, to receipt: Receipt) {
        guard let name = name, !name.isEmpty else {
            receipt.category = nil
            return
        }
        
        let request: NSFetchRequest<ExpenseCategory> = ExpenseCategory.fetchRequest()
        request.predicate = NSPredicate(format: "name == %@", name)
        
        do {
            let matches = try context.fetch(request)
            receipt.category = matches.first
        } catch {
            print("Error linking category: \(error)")
        }
    }
}
