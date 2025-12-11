import XCTest

@testable import SmartExpense

@testable import SmartExpense

#if false
final class HomeViewModelTests: XCTestCase {

    func testLoadsSummaryAndFormatsValues() async {
        let service = MockService()
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"

        let viewModel = await MainActor.run {
            HomeViewModel(service: service, currencyFormatter: formatter)
        }

        await MainActor.run {
            viewModel.refresh()
        }

        // Delay briefly to allow async task to complete in this simple test environment.
        try? await Task.sleep(nanoseconds: 100_000_000)

        await MainActor.run {
            XCTAssertEqual(viewModel.periodTitle, "This Month")
            XCTAssertTrue(viewModel.totalSpendText.contains("123.45"))
            // XCTAssertTrue(viewModel.averageDailySpendText.contains("6.78"))
            XCTAssertTrue(viewModel.topMerchantTitle.contains("Coffee Place"))
            XCTAssertTrue(viewModel.topCategoryTitle.contains("Food & Dining"))
        }
    }
}

// MARK: - Test Doubles

private struct MockService: HomeOverviewServiceProtocol {
    func loadSummary(start: Date, end: Date, period: HomePeriod) async throws -> HomeSummary {
        HomeSummary(
            periodDescription: "This Month",
            totalSpend: 123.45,
            previousPeriodTotalSpend: 100.00,
            averageDailySpend: 6.78,
            topMerchantName: "Coffee Place",
            topMerchantAmount: 50.0,
            topCategoryName: "Food & Dining",
            topCategoryAmount: 70.0,
            biggestPurchase: (amount: 50.0, merchant: "Coffee Place", date: Date()),
            biggestPurchaseReceiptId: UUID(),
            categorySpending: [("Food & Dining", 70.0), ("Others", 53.45)],
            spendingTrend: []
        )
    }
}
#endif


