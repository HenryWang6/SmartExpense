//
//  CategoryDataService.swift
//  SmartExpense
//
//  Created by Antigravity on 2025-12-12.
//

import CoreData

/// Service responsible for all Category-related data operations
class CategoryDataService: DataService {
    let context: NSManagedObjectContext
    private let receiptService: ReceiptDataService
    
    required init(context: NSManagedObjectContext) {
        self.context = context
        self.receiptService = ReceiptDataService(context: context)
    }
    
    // MARK: - Update
    
    /// Updates a category's name and handles the cascading update to associated receipts
    func updateCategoryName(_ category: ExpenseCategory, to newName: String) throws {
        let oldName = category.name ?? ""
        
        // Update the category itself
        category.name = newName
        
        // If the name actually changed, update all associated receipts
        if oldName != newName && !oldName.isEmpty {
            try receiptService.updateCategoryOfReceipts(from: oldName, to: newName)
        } else {
            // Just save the category change (e.g. if only name changed but it was empty before, or no change needed)
            try save()
        }
    }
    
    // MARK: - CRUD
    
    func createCategory(
        name: String,
        iconValue: String,
        iconType: String = "sfSymbol",
        colorHex: String,
        isDefault: Bool = false,
        sortOrder: Int16 = 0
    ) throws -> ExpenseCategory {
        let category = ExpenseCategory(context: context)
        category.id = UUID()
        category.name = name
        category.iconValue = iconValue
        category.iconType = iconType
        category.colorHex = colorHex
        category.isDefault = isDefault
        category.sortOrder = Int32(sortOrder)
        
        try save()
        return category
    }
    
    func delete(_ category: ExpenseCategory) throws {
        // Logic for deleting a category. 
        // Note: We might want to set associated receipts to "Uncategorized" or handle them.
        // For now, simple delete.
        context.delete(category)
        try save()
    }
}
