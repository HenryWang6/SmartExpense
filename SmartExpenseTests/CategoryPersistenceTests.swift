//
//  CategoryPersistenceTests.swift
//  SmartExpenseTests
//
//  Created by Antigravity on 2025-12-11.
//

import XCTest
import CoreData
@testable import SmartExpense

final class CategoryPersistenceTests: XCTestCase {
    
    var persistenceController: PersistenceController!
    var viewContext: NSManagedObjectContext!
    
    override func setUp() {
        super.setUp()
        // This init() triggers the migration service automatically in Persistence.swift
        persistenceController = PersistenceController(inMemory: true)
        viewContext = persistenceController.container.viewContext
    }
    
    override func tearDown() {
        persistenceController = nil
        viewContext = nil
        super.tearDown()
    }
    
    func testDefaultCategorySeeding() throws {
        // Migration runs on init, so defaults should be present immediately
        
        let request: NSFetchRequest<ExpenseCategory> = ExpenseCategory.fetchRequest()
        let categories = try viewContext.fetch(request)
        
        // Check count (10 defaults)
        XCTAssertEqual(categories.count, 10, "Should have seeded 10 default categories")
        
        // Verify a specific one
        if let housing = categories.first(where: { $0.name == "Housing" }) {
            XCTAssertEqual(housing.iconValue, "🏠")
            XCTAssertEqual(housing.colorHex, "#9B59B6")
            XCTAssertTrue(housing.isDefault)
        } else {
            XCTFail("Housing category not found")
        }
    }
    
    func testMigrationLinksExistingReceipts() throws {
        // 1. Create receipts that "missed" the initial migration (simulating pre-existing data flow, or new import)
        // Since we are adding them AFTER init, they have no category yet.
        
        let receiptGroceries = Receipt(context: viewContext)
        receiptGroceries.id = UUID()
        receiptGroceries.merchantName = "Test Grocer"
        receiptGroceries.merchantCategory = "Groceries" // Should match default
        receiptGroceries.date = Date()
        
        let receiptCustom = Receipt(context: viewContext)
        receiptCustom.id = UUID()
        receiptCustom.merchantName = "Test Unknown"
        receiptCustom.merchantCategory = "My Special Category" // Should create new
        receiptCustom.date = Date()
        
        try viewContext.save()
        
        // 2. Manually trigger migration again (simulate next app launch or retry)
        CategoryMigrationService.shared.migrate(in: viewContext)
        
        // 3. Verify
        XCTAssertNotNil(receiptGroceries.category, "Should be linked to Groceries")
        XCTAssertEqual(receiptGroceries.category?.name, "Groceries")
        XCTAssertTrue(receiptGroceries.category?.isDefault ?? false)
        
        XCTAssertNotNil(receiptCustom.category, "Should be linked to new category")
        XCTAssertEqual(receiptCustom.category?.name, "My Special Category".capitalized)
        XCTAssertFalse(receiptCustom.category?.isDefault ?? true)
        
        // Verify duplicate handling
        // If we add another receipt with "My Special Category", it should link to the SAME one we just created
        let receiptCustom2 = Receipt(context: viewContext)
        receiptCustom2.merchantCategory = "my special category" // Lowercase
        try viewContext.save()
        
        CategoryMigrationService.shared.migrate(in: viewContext)
        
        XCTAssertEqual(receiptCustom2.category, receiptCustom.category, "Should reuse existing custom category")
    }
}
