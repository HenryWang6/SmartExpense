import Foundation

/// Abstraction for loading Home screen overview data.
protocol HomeOverviewServiceProtocol {
    /// Loads summary data for the specified period range.
    func loadSummary(start: Date, end: Date, period: HomePeriod) async throws -> HomeSummary
}

/// Temporary mock implementation backed by static data.
/// Replace this with a real persistence-backed implementation when storage is available.
struct HomeOverviewMockService: HomeOverviewServiceProtocol {
    func loadSummary(start: Date, end: Date, period: HomePeriod) async throws -> HomeSummary {
        // Fake numbers for now; in a real implementation these would be derived from stored receipts.
        return HomeSummary(
            periodDescription: "This Month",
            totalSpend: 1234.56,
            previousPeriodTotalSpend: 1180.00,
            averageDailySpend: 82.30,
            topMerchantName: "Sample Coffee",
            topMerchantAmount: 245.90,
            topCategoryName: "Food & Dining",
            topCategoryAmount: 530.20,
            biggestPurchase: (amount: 120.50, merchant: "Tech Store", date: Date().addingTimeInterval(-86400 * 3)),
            biggestPurchaseReceiptId: nil,
            categorySpending: [
                ("Food & Dining", 530.20, "#e74c3c", "carrot"),
                ("Shopping", 320.50, "#3498db", "cart"),
                ("Transport", 150.00, "#f1c40f", "car"),
                ("Entertainment", 120.00, "#9b59b6", "gamecontroller"),
                ("Others", 113.86, "#95a5a6", "circle")
            ],
            spendingTrend: [
                (Date().addingTimeInterval(-86400 * 30), 500),
                (Date().addingTimeInterval(-86400 * 20), 800),
                (Date().addingTimeInterval(-86400 * 10), 600),
                (Date(), 1234.56)
            ]
        )
    }
}


