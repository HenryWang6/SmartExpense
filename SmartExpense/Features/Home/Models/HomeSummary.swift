import Foundation

/// Lightweight summary for the Home screen KPIs for a given period.
struct HomeSummary {
    let periodDescription: String
    let totalSpend: Decimal
    let previousPeriodTotalSpend: Decimal?
    let averageDailySpend: Decimal
    let topMerchantName: String?
    let topMerchantAmount: Decimal?
    let topCategoryName: String?
    let topCategoryAmount: Decimal?
    let biggestPurchase: (amount: Decimal, merchant: String, date: Date)?
    let categorySpending: [(category: String, amount: Decimal)]
}


