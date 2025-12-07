
import XCTest
@testable import SmartExpense

final class ReceiptParsingTests: XCTestCase {

    var service: ReceiptOCRService!

    override func setUp() {
        super.setUp()
        service = ReceiptOCRService.shared
    }

    // MARK: - Merchant Tests

    func testMerchantExtraction_Simple() {
        let lines = [
            "Walmart Supercenter",
            "123 Main St",
            "Anytown, CA 90210"
        ]
        let merchant = service.extractMerchantName(from: lines)
        XCTAssertEqual(merchant, "Walmart Supercenter")
    }

    func testMerchantExtraction_WithNoise() {
        let lines = [
            "Customer Copy",
            "Welcome to",
            "Target Store 001",
            "123456789"
        ]
        let merchant = service.extractMerchantName(from: lines)
        XCTAssertEqual(merchant, "Target Store 001") // "Customer Copy" and "Welcome to" should be skipped or "Welcome to" might be short? "Welcome to" is > 3 chars. 
        // Wait, "Welcome" is in invalid patterns. "Welcome to" contains "Welcome"? 
        // My code: trimmed.range(of: pattern) != nil. So "Welcome to" contains "Welcome" -> skipped.
    }
    
    // MARK: - Date Tests
    
    func testDateExtraction_MMddyyyy() {
        let lines = ["Date: 12/25/2025"]
        let date = service.extractDate(from: lines)
        // Check components
        let components = Calendar.current.dateComponents([.year, .month, .day], from: date!)
        XCTAssertEqual(components.year, 2025)
        XCTAssertEqual(components.month, 12)
        XCTAssertEqual(components.day, 25)
    }
    
    func testDateExtraction_MMMddyyyy_WithTime() {
        let lines = ["Dec 06, 2025 10:30 PM"]
        let date = service.extractDate(from: lines)
        XCTAssertNotNil(date)
        
        let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: date!)
        XCTAssertEqual(components.year, 2025)
        XCTAssertEqual(components.month, 12)
        XCTAssertEqual(components.day, 6)
        XCTAssertEqual(components.hour, 22) // 10 PM -> 22
        XCTAssertEqual(components.minute, 30)
    }
    
    func testDateExtraction_SeparateLines() {
        let lines = [
            "Transaction Date:",
            "2025-01-15",
            "Time: 14:45"
        ]
        let date = service.extractDate(from: lines)
        XCTAssertNotNil(date)
        
        let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: date!)
        XCTAssertEqual(components.year, 2025)
        XCTAssertEqual(components.month, 1)
        XCTAssertEqual(components.day, 15)
        XCTAssertEqual(components.hour, 14)
        XCTAssertEqual(components.minute, 45)
    }

    // MARK: - Total Tests

    func testTotalExtraction_Explicit() {
        let lines = [
            "Subtotal: $10.00",
            "Tax: $1.00",
            "Total: $11.00",
            "Thank you"
        ]
        let total = service.extractTotalAmount(from: lines)
        XCTAssertEqual(total, 11.00)
    }
    
    func testTotalExtraction_Keywords() {
        let lines = [
            "Balance Due",
            "$45.50"
        ]
        let total = service.extractTotalAmount(from: lines)
        XCTAssertEqual(total, 45.50)
    }
    
    func testTotalExtraction_MaxAmountFallback() {
        let lines = [
            "Item 1 ... 5.00",
            "Item 2 ... 20.00",
            "Tax ... 2.00" // No "Total" keyword
        ]
        // Should return max amount (20.00) if no total keyword found?
        // My code returns max if no explicit total.
        let total = service.extractTotalAmount(from: lines)
        XCTAssertEqual(total, 20.00)
    }
    
    func testTotalExtraction_AmountOnPreviousLine() {
        let lines = [
            "Total",
            "100.00"
        ]
        // Implementation check: 
        // Iterating reversed. 
        // 1. "100.00". Check prev line (index - 1). 
        // reversed enumerated gives index in original array? 
        // enumerated() returns (index, element). reversed() keeps the original index? No. 
        // [0: "Total", 1: "100.00"]. enumerated() -> [(0, "Total"), (1, "100.00")]. reversed() -> (1, "100.00"), (0, "Total").
        // Processing (1, "100.00"). index=1. prevLine = lines[0] = "Total". contextHasTotal = true. Found!
        let total = service.extractTotalAmount(from: lines)
        XCTAssertEqual(total, 100.00)
    }
}
