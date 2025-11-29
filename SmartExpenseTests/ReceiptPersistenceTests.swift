//
//  ReceiptPersistenceTests.swift
//  SmartExpenseTests
//
//  Created by Antigravity on 2025-11-29.
//

import XCTest
import CoreData
@testable import SmartExpense

final class ReceiptPersistenceTests: XCTestCase {
    
    var persistenceController: PersistenceController!
    var viewContext: NSManagedObjectContext!
    
    override func setUp() {
        super.setUp()
        persistenceController = PersistenceController(inMemory: true)
        viewContext = persistenceController.container.viewContext
    }
    
    override func tearDown() {
        persistenceController = nil
        viewContext = nil
        super.tearDown()
    }
    
    // MARK: - Receipt CRUD Tests
    
    func testCreateReceipt() throws {
        // Given
        let receipt = Receipt(context: viewContext)
        receipt.id = UUID()
        receipt.merchantName = "Test Merchant"
        receipt.date = Date()
        receipt.totalAmount = 42.99
        receipt.isVoiceInput = false
        receipt.createdAt = Date()
        
        // When
        try viewContext.save()
        
        // Then
        let fetchRequest: NSFetchRequest<Receipt> = Receipt.fetchRequest()
        let results = try viewContext.fetch(fetchRequest)
        
        XCTAssertEqual(results.count, 1)
        XCTAssertEqual(results.first?.merchantName, "Test Merchant")
        XCTAssertEqual(results.first?.totalAmount, 42.99)
        XCTAssertEqual(results.first?.isVoiceInput, false)
    }
    
    func testFetchReceipts() throws {
        // Given - Create multiple receipts
        for i in 0..<5 {
            let receipt = Receipt(context: viewContext)
            receipt.id = UUID()
            receipt.merchantName = "Merchant \(i)"
            receipt.date = Date()
            receipt.totalAmount = Double(i * 10)
            receipt.isVoiceInput = i % 2 == 0
            receipt.createdAt = Date()
        }
        try viewContext.save()
        
        // When
        let fetchRequest: NSFetchRequest<Receipt> = Receipt.fetchRequest()
        let results = try viewContext.fetch(fetchRequest)
        
        // Then
        XCTAssertEqual(results.count, 5)
    }
    
    func testDeleteReceipt() throws {
        // Given
        let receipt = Receipt(context: viewContext)
        receipt.id = UUID()
        receipt.merchantName = "Delete Me"
        receipt.date = Date()
        receipt.totalAmount = 100.0
        receipt.createdAt = Date()
        try viewContext.save()
        
        // When
        viewContext.delete(receipt)
        try viewContext.save()
        
        // Then
        let fetchRequest: NSFetchRequest<Receipt> = Receipt.fetchRequest()
        let results = try viewContext.fetch(fetchRequest)
        XCTAssertEqual(results.count, 0)
    }
    
    func testReceiptWithItems() throws {
        // Given
        let receipt = Receipt(context: viewContext)
        receipt.id = UUID()
        receipt.merchantName = "Grocery Store"
        receipt.date = Date()
        receipt.totalAmount = 50.00
        receipt.createdAt = Date()
        
        let item1 = ReceiptItem(context: viewContext)
        item1.id = UUID()
        item1.name = "Milk"
        item1.price = 3.99
        item1.quantity = 2
        item1.receipt = receipt
        
        let item2 = ReceiptItem(context: viewContext)
        item2.id = UUID()
        item2.name = "Bread"
        item2.price = 2.50
        item2.quantity = 1
        item2.receipt = receipt
        
        // When
        try viewContext.save()
        
        // Then
        let fetchRequest: NSFetchRequest<Receipt> = Receipt.fetchRequest()
        let results = try viewContext.fetch(fetchRequest)
        
        XCTAssertEqual(results.count, 1)
        XCTAssertEqual(results.first?.items?.count, 2)
    }
    
    func testCascadeDeleteReceiptDeletesItems() throws {
        // Given
        let receipt = Receipt(context: viewContext)
        receipt.id = UUID()
        receipt.merchantName = "Test Cascade"
        receipt.date = Date()
        receipt.totalAmount = 25.00
        receipt.createdAt = Date()
        
        let item = ReceiptItem(context: viewContext)
        item.id = UUID()
        item.name = "Test Item"
        item.price = 25.00
        item.quantity = 1
        item.receipt = receipt
        
        try viewContext.save()
        
        // When
        viewContext.delete(receipt)
        try viewContext.save()
        
        // Then
        let itemFetchRequest: NSFetchRequest<ReceiptItem> = ReceiptItem.fetchRequest()
        let itemResults = try viewContext.fetch(itemFetchRequest)
        XCTAssertEqual(itemResults.count, 0, "Items should be cascade deleted with receipt")
    }
}
