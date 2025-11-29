import Foundation

/// Lightweight summary for the Home screen KPIs for a given period.
struct HomeSummary {
    let periodDescription: String
    let totalSpend: Decimal
    let averageDailySpend: Decimal
    let topMerchantName: String?
    let topMerchantAmount: Decimal?
    let topCategoryName: String?
    let topCategoryAmount: Decimal?
}


