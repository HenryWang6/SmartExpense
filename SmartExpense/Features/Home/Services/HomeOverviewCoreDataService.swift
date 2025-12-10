import Foundation
import CoreData
import SwiftUI

struct HomeOverviewCoreDataService: HomeOverviewServiceProtocol, @unchecked Sendable {
    private let viewContext: NSManagedObjectContext
    private let calendar = Calendar.current
    
    @MainActor
    init(viewContext: NSManagedObjectContext) {
        self.viewContext = viewContext
    }
    
    @MainActor
    func loadSummary(start: Date, end: Date, period: HomePeriod) async throws -> HomeSummary {
        // 1. Fetch Receipts in range for the main summary
        let request = Receipt.fetchRequest()
        request.predicate = NSPredicate(format: "date >= %@ AND date <= %@", start as NSDate, end as NSDate)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Receipt.date, ascending: false)]
        
        let receipts = try viewContext.fetch(request)
        
        // 2. Calculate Total Spend
        let totalSpend = receipts.reduce(Decimal(0)) { sum, receipt in sum + Decimal(receipt.totalAmount) }
        
        // 3. Calculate Previous Period Spend
        let duration = end.timeIntervalSince(start)
        let prevEnd = start.addingTimeInterval(-1)
        let prevStart = prevEnd.addingTimeInterval(-duration)
        
        let prevRequest = Receipt.fetchRequest()
        prevRequest.predicate = NSPredicate(format: "date >= %@ AND date <= %@", prevStart as NSDate, prevEnd as NSDate)
        let prevReceipts = try viewContext.fetch(prevRequest)
        let prevTotalSpend = prevReceipts.reduce(Decimal(0)) { sum, receipt in sum + Decimal(receipt.totalAmount) }
        
        // 4. Average Daily Spend
        let days = max(1, calendar.dateComponents([.day], from: start, to: end).day ?? 1)
        let averageDailySpend = totalSpend / Decimal(days)
        
        // 5. Top Merchant
        let merchantSpending = Dictionary(grouping: receipts, by: { $0.merchantName ?? "Unknown" })
            .mapValues { $0.reduce(Decimal(0)) { sum, receipt in sum + Decimal(receipt.totalAmount) } }
        
        let topMerchant = merchantSpending.max(by: { $0.value < $1.value })
        
        // 6. Top Category & Category Distribution
        var categoryMap: [String: Decimal] = [:]
        
        for receipt in receipts {
            if let items = receipt.items as? Set<ReceiptItem>, !items.isEmpty {
                for item in items {
                    let cat = item.category?.isEmpty == false ? item.category! : "Uncategorized"
                    categoryMap[cat, default: 0] += Decimal(item.subtotal)
                }
            } else {
                let cat = receipt.merchantCategory?.isEmpty == false ? receipt.merchantCategory! : "Uncategorized"
                categoryMap[cat, default: 0] += Decimal(receipt.totalAmount)
            }
        }
        
        let topCategory = categoryMap.max(by: { $0.value < $1.value })
        
        let sortedCategories = categoryMap.sorted(by: { $0.value > $1.value }).map { (category: $0.key, amount: $0.value) }
        
        // 7. Biggest Purchase
        let biggestReceipt = receipts.max(by: { $0.totalAmount < $1.totalAmount })
        let biggestPurchaseData: (amount: Decimal, merchant: String, date: Date)?
        let biggestPurchaseId: NSManagedObjectID?
        if let biggest = biggestReceipt {
            biggestPurchaseData = (Decimal(biggest.totalAmount), biggest.merchantName ?? "Unknown", biggest.date ?? Date())
            biggestPurchaseId = biggest.objectID
        } else {
            biggestPurchaseData = nil
            biggestPurchaseId = nil
        }
        
        // 8. Spending Trend
        let trend = try await calculateTrend(currentStart: start, currentEnd: end, period: period)
        
        return HomeSummary(
            periodDescription: "", 
            totalSpend: totalSpend,
            previousPeriodTotalSpend: prevTotalSpend,
            averageDailySpend: averageDailySpend,
            topMerchantName: topMerchant?.key,
            topMerchantAmount: topMerchant?.value,
            topCategoryName: topCategory?.key,
            topCategoryAmount: topCategory?.value,
            biggestPurchase: biggestPurchaseData,
            biggestPurchaseReceiptId: biggestPurchaseId,
            categorySpending: sortedCategories,
            spendingTrend: trend
        )
    }
    
    private func calculateTrend(currentStart: Date, currentEnd: Date, period: HomePeriod) async throws -> [(Date, Decimal)] {
        // Fetch all receipts in the selected period range
        let request = Receipt.fetchRequest()
        request.predicate = NSPredicate(format: "date >= %@ AND date <= %@", currentStart as NSDate, currentEnd as NSDate)
        let receipts = try viewContext.fetch(request)
        
        // Determine granularity and range iteration
        let component: Calendar.Component
        
        switch period {
        case .weekly, .monthly:
            component = .day
        case .yearly:
            component = .month
        }
        
        // Group receipts by the appropriate time unit
        var groupedSpending: [Date: Decimal] = [:]
        
        for receipt in receipts {
            guard let date = receipt.date else { continue }
            
            // Normalize date to the start of the granularity unit (day or month)
            let normalizedDate: Date
            if component == .day {
                normalizedDate = calendar.startOfDay(for: date)
            } else {
                let components = calendar.dateComponents([.year, .month], from: date)
                guard let d = calendar.date(from: components) else { continue }
                normalizedDate = d
            }
            
            groupedSpending[normalizedDate, default: 0] += Decimal(receipt.totalAmount)
        }
        
        // Generate continuous data points filling the range
        var trendData: [(Date, Decimal)] = []
        var currentDate = currentStart
        
        // Iterate from start to end using the component
        // Note: We use logical comparison. For 'monthly' period with 'day' component, we go day by day.
        // For 'yearly' period with 'month' component, we go month by month.
        while currentDate <= currentEnd {
            let normalizedKey: Date
            if component == .day {
                normalizedKey = calendar.startOfDay(for: currentDate)
            } else {
                let components = calendar.dateComponents([.year, .month], from: currentDate)
                normalizedKey = calendar.date(from: components) ?? currentDate
            }
            
            let amount = groupedSpending[normalizedKey] ?? 0
            trendData.append((normalizedKey, amount))
            
            // Advance to next step
            guard let nextDate = calendar.date(byAdding: component, value: 1, to: currentDate) else { break }
            currentDate = nextDate
        }
        
        return trendData
    }
}
