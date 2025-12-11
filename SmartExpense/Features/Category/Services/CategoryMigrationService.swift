//
//  CategoryMigrationService.swift
//  SmartExpense
//
//  Created by Antigravity on 2025-12-11.
//

import Foundation
import CoreData
import SwiftUI

class CategoryMigrationService {
    static let shared = CategoryMigrationService()
    
    private init() {}
    
    struct DefaultCategory {
        let name: String
        let iconValue: String
        let colorHex: String
        let sortOrder: Int32
    }
    
    private let defaultCategories: [DefaultCategory] = [
        DefaultCategory(name: "Housing", iconValue: "🏠", colorHex: "#9B59B6", sortOrder: 0),
        DefaultCategory(name: "Groceries", iconValue: "🛒", colorHex: "#2ECC71", sortOrder: 1),
        DefaultCategory(name: "Dining Out", iconValue: "🍔", colorHex: "#D35400", sortOrder: 2),
        DefaultCategory(name: "Coffee", iconValue: "☕️", colorHex: "#6D4C41", sortOrder: 3),
        DefaultCategory(name: "Transport", iconValue: "🚘", colorHex: "#3498DB", sortOrder: 4),
        DefaultCategory(name: "Utilities", iconValue: "💡", colorHex: "#1ABC9C", sortOrder: 5),
        DefaultCategory(name: "Shopping", iconValue: "🛍️", colorHex: "#F1C40F", sortOrder: 6),
        DefaultCategory(name: "Health", iconValue: "💊", colorHex: "#E74C3C", sortOrder: 7),
        DefaultCategory(name: "Entertainment", iconValue: "🎬", colorHex: "#F39C12", sortOrder: 8),
        DefaultCategory(name: "Insurance", iconValue: "🛡️", colorHex: "#5B5EA6", sortOrder: 9)
    ]
    
    func migrate(in context: NSManagedObjectContext) {
        performUpdates(in: context)
    }
    
    private func performUpdates(in context: NSManagedObjectContext) {
        // 1. Seed Defaults
        let categories = seedDefaultCategories(in: context)
        
        // 2. Link Existing Receipts
        linkExistingReceipts(in: context, validCategories: categories)
        
        // 3. Save
        if context.hasChanges {
            do {
                try context.save()
                print("Category Migration Completed Successfully")
            } catch {
                print("Category Migration Failed: \(error.localizedDescription)")
            }
        }
    }
    
    private func seedDefaultCategories(in context: NSManagedObjectContext) -> [ExpenseCategory] {
        let fetchRequest: NSFetchRequest<ExpenseCategory> = ExpenseCategory.fetchRequest()
        
        do {
            let existing = try context.fetch(fetchRequest)
            
            // If we already have categories, return them (assuming defaults are among them or user modified them)
            // However, for robust migration, we might want to checks by name.
            // For now, if DB is empty of categories, we seed.
            
            if existing.isEmpty {
                var newCategories: [ExpenseCategory] = []
                for def in defaultCategories {
                    let cat = ExpenseCategory(context: context)
                    cat.id = UUID()
                    cat.name = def.name
                    cat.iconValue = def.iconValue
                    cat.iconType = "emoji" // Default to emoji
                    cat.colorHex = def.colorHex
                    cat.isDefault = true
                    cat.sortOrder = def.sortOrder
                    newCategories.append(cat)
                }
                return newCategories
            }
            return existing
        } catch {
            print("Failed to fetch categories: \(error)")
            return []
        }
    }
    
    private func linkExistingReceipts(in context: NSManagedObjectContext, validCategories: [ExpenseCategory]) {
        // Build map from validCategories first (which are already in context)
        var categoryMap: [String: ExpenseCategory] = [:]
        for cat in validCategories {
            if let name = cat.name {
                categoryMap[name.lowercased()] = cat
            }
        }
        
        let fetchRequest: NSFetchRequest<Receipt> = Receipt.fetchRequest()
        // Filter: has merchantCategory but no category relationship
        fetchRequest.predicate = NSPredicate(format: "category == nil AND merchantCategory != nil AND merchantCategory != ''")
        
        do {
            let receipts = try context.fetch(fetchRequest)
            
            for receipt in receipts {
                guard let rawName = receipt.merchantCategory else { continue }
                let key = rawName.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
                
                if let existing = categoryMap[key] {
                    receipt.category = existing
                } else {
                    // Create new category for this custom string
                    let newCat = ExpenseCategory(context: context)
                    newCat.id = UUID()
                    newCat.name = rawName.capitalized // Normalize
                    newCat.iconValue = "🏷️" // Default icon for unknown
                    newCat.iconType = "emoji"
                    newCat.colorHex = "#95A5A6" // Slate
                    newCat.isDefault = false
                    newCat.sortOrder = 999
                    
                    receipt.category = newCat
                    // Update map to reuse this new category
                    categoryMap[key] = newCat
                }
            }
        } catch {
            print("Failed to fetch receipts for migration: \(error)")
        }
    }
}
