import Foundation
import CoreData
import SwiftUI

struct HomeOverviewCoreDataService: HomeOverviewServiceProtocol {
    private let viewContext: NSManagedObjectContext
    private let calendar = Calendar.current
    
    init(viewContext: NSManagedObjectContext) {
        self.viewContext = viewContext
    }
    
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
        
        let sortedCategories = categoryMap.sorted(by: { $0.value > $1.value })
        var finalCategories: [(String, Decimal)] = []
        
        if sortedCategories.count > 5 {
            finalCategories = Array(sortedCategories.prefix(4))
            let othersSum = sortedCategories.suffix(from: 4).reduce(Decimal(0)) { $0 + $1.value }
            finalCategories.append(("Others", othersSum))
        } else {
            finalCategories = sortedCategories
        }
        
        // 7. Biggest Purchase
        let biggestReceipt = receipts.max(by: { $0.totalAmount < $1.totalAmount })
        let biggestPurchaseData: (amount: Decimal, merchant: String, date: Date)?
        if let biggest = biggestReceipt {
            biggestPurchaseData = (Decimal(biggest.totalAmount), biggest.merchantName ?? "Unknown", biggest.date ?? Date())
        } else {
            biggestPurchaseData = nil
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
            categorySpending: finalCategories,
            spendingTrend: trend
        )
    }
    
    private func calculateTrend(currentStart: Date, currentEnd: Date, period: HomePeriod) async throws -> [(Date, Decimal)] {
        var trendData: [(Date, Decimal)] = []
        
        let trendStart: Date
        let component: Calendar.Component
        let count: Int
        
        switch period {
        case .monthly:
            // Past 6 periods (including current)
            count = 6
            component = .month
            trendStart = calendar.date(byAdding: .month, value: -5, to: currentStart)!
        case .weekly:
            // Past 12 weeks
            count = 12
            component = .weekOfYear
            trendStart = calendar.date(byAdding: .weekOfYear, value: -11, to: currentStart)!
        case .daily:
            // Past 30 days
            count = 30
            component = .day
            trendStart = calendar.date(byAdding: .day, value: -29, to: currentStart)!
        case .yearly:
            return []
        }
        
        // Fetch all receipts in the trend range
        let request = Receipt.fetchRequest()
        request.predicate = NSPredicate(format: "date >= %@ AND date <= %@", trendStart as NSDate, currentEnd as NSDate)
        let receipts = try viewContext.fetch(request)
        
        // Group receipts by period
        var groupedSpending: [Date: Decimal] = [:]
        
        for receipt in receipts {
            guard let date = receipt.date else { continue }
            
            // Normalize date to the start of the period
            let normalizedDate: Date
            switch period {
            case .monthly:
                let components = calendar.dateComponents([.year, .month], from: date)
                normalizedDate = calendar.date(from: components)!
            case .weekly:
                let components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: date)
                normalizedDate = calendar.date(from: components)!
            case .daily:
                normalizedDate = calendar.startOfDay(for: date)
            case .yearly:
                continue
            }
            
            groupedSpending[normalizedDate, default: 0] += Decimal(receipt.totalAmount)
        }
        
        // Generate all data points (fill with 0 if missing)
        for i in 0..<count {
            let date = calendar.date(byAdding: component, value: i, to: trendStart)!
            let amount = groupedSpending[date] ?? 0
            trendData.append((date, amount))
        }
        
        return trendData
    }
}
