import Foundation

/// Abstraction for loading Home screen overview data.
protocol HomeOverviewServiceProtocol {
    /// Loads summary data for the current default period (e.g., this month).
    func loadCurrentSummary() async throws -> HomeSummary
}

/// Temporary mock implementation backed by static data.
/// Replace this with a real persistence-backed implementation when storage is available.
struct HomeOverviewMockService: HomeOverviewServiceProtocol {
    func loadCurrentSummary() async throws -> HomeSummary {
        // Fake numbers for now; in a real implementation these would be derived from stored receipts.
        return HomeSummary(
            periodDescription: "This Month",
            totalSpend: 1234.56,
            averageDailySpend: 82.30,
            topMerchantName: "Sample Coffee",
            topMerchantAmount: 245.90,
            topCategoryName: "Food & Dining",
            topCategoryAmount: 530.20
        )
    }
}


