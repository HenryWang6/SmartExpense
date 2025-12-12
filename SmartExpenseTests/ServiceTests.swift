//
//  ServiceTests.swift
//  SmartExpenseTests
//
//  Created by Antigravity on 2025-12-12.
//

import XCTest
import CoreData
@testable import SmartExpense

class ServiceTests: XCTestCase {
    var persistenceController: PersistenceController!
    var context: NSManagedObjectContext!
    var receiptService: ReceiptDataService!
    var categoryService: CategoryDataService!
    
    override func setUp() {
        super.setUp()
        persistenceController = PersistenceController(inMemory: true)
        context = persistenceController.container.viewContext
        receiptService = ReceiptDataService(context: context)
        categoryService = CategoryDataService(context: context)
    }
    
    override func tearDown() {
        persistenceController = nil
        context = nil
        receiptService = nil
        categoryService = nil
        super.tearDown()
    }
    
    func testCreateReceipt() throws {
        let receipt = try receiptService.createReceipt(merchantName: "Test Merchant", amount: 10.0, date: Date(), category: "Food")
        
        XCTAssertNotNil(receipt.id)
        XCTAssertEqual(receipt.merchantName, "Test Merchant")
        XCTAssertEqual(receipt.totalAmount, 10.0)
        XCTAssertEqual(receipt.merchantCategory, "Food")
    }
    
    func testCategoryRenameUpdatesReceipts() throws {
        // Given
        let _ = try receiptService.createReceipt(merchantName: "R1", amount: 10, date: Date(), category: "Food")
        let _ = try receiptService.createReceipt(merchantName: "R2", amount: 20, date: Date(), category: "Food")
        let _ = try receiptService.createReceipt(merchantName: "R3", amount: 30, date: Date(), category: "Travel")
        
        let category = try categoryService.createCategory(name: "Food", iconValue: "🍔", colorHex: "#FFFFFF")
        
        // When
        try categoryService.updateCategoryName(category, to: "Dining")
        
        // Then
        let request: NSFetchRequest<Receipt> = Receipt.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "merchantName", ascending: true)]
        let receipts = try context.fetch(request)
        
        let r1 = receipts.first(where: { $0.merchantName == "R1" })!
        let r2 = receipts.first(where: { $0.merchantName == "R2" })!
        let r3 = receipts.first(where: { $0.merchantName == "R3" })!
        
        XCTAssertEqual(r1.merchantCategory, "Dining")
        XCTAssertEqual(r2.merchantCategory, "Dining")
        XCTAssertEqual(r3.merchantCategory, "Travel") // Should not change
    }
}
