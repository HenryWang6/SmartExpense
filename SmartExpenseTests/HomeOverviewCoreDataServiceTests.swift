import XCTest
import CoreData
@testable import SmartExpense

class HomeOverviewCoreDataServiceTests: XCTestCase {
    var persistenceController: PersistenceController!
    var service: HomeOverviewCoreDataService!
    var viewContext: NSManagedObjectContext!
    
    override func setUp() {
        super.setUp()
        persistenceController = PersistenceController(inMemory: true)
        viewContext = persistenceController.container.viewContext
        service = HomeOverviewCoreDataService(viewContext: viewContext)
    }
    
    override func tearDown() {
        persistenceController = nil
        service = nil
        viewContext = nil
        super.tearDown()
    }
    
    func testLoadSummaryCalculatesTotalSpend() async throws {
        // Given
        createReceipt(amount: 100, date: Date())
        createReceipt(amount: 50, date: Date())
        
        // When
        let summary = try await service.loadCurrentSummary()
        
        // Then
        XCTAssertEqual(summary.totalSpend, 150)
    }
    
    func testLoadSummaryCalculatesTopCategory() async throws {
        // Given
        let r1 = createReceipt(amount: 100, date: Date())
        createItem(receipt: r1, category: "Food", amount: 60)
        createItem(receipt: r1, category: "Transport", amount: 40)
        
        let r2 = createReceipt(amount: 50, date: Date())
        createItem(receipt: r2, category: "Food", amount: 50)
        
        // When
        let summary = try await service.loadCurrentSummary()
        
        // Then
        XCTAssertEqual(summary.topCategoryName, "Food")
        XCTAssertEqual(summary.topCategoryAmount, 110)
    }
    
    // Helper methods
    @discardableResult
    func createReceipt(amount: Double, date: Date) -> Receipt {
        let receipt = Receipt(context: viewContext)
        receipt.id = UUID()
        receipt.totalAmount = amount
        receipt.date = date
        receipt.merchantName = "Test Merchant"
        receipt.createdAt = Date()
        return receipt
    }
    
    func createItem(receipt: Receipt, category: String, amount: Double) {
        let item = ReceiptItem(context: viewContext)
        item.id = UUID()
        item.category = category
        item.subtotal = amount
        item.receipt = receipt
    }
}
