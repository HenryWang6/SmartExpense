import Foundation
import CoreData
import SwiftUI

struct HomeOverviewCoreDataService: HomeOverviewServiceProtocol {
    private let viewContext: NSManagedObjectContext
    private let calendar = Calendar.current
    
    init(viewContext: NSManagedObjectContext) {
        self.viewContext = viewContext
    }
    
    func loadCurrentSummary() async throws -> HomeSummary {
        // For now, we default to "This Month" if no specific period is passed.
        // In the future, we should update the protocol to accept a date range or period.
        // However, the ViewModel currently manages the period and just calls loadCurrentSummary().
        // Wait, the ViewModel *does* have a selectedPeriod.
        // But the protocol `loadCurrentSummary()` doesn't take arguments.
        // The ViewModel implementation in `load()` says:
        // "For now, we just load the mock summary"
        
        // To properly support the period selection in the ViewModel, we need to update the protocol
        // or the ViewModel needs to pass the range.
        // Let's look at the ViewModel again. It has `selectedPeriod` and `currentReferenceDate`.
        // But it calls `service.loadCurrentSummary()`.
        
        // I should probably update the protocol to accept the period/date, OR
        // for this specific task step, I'll implement `loadCurrentSummary` to return *something* meaningful,
        // but ideally I should refactor the protocol to be useful.
        
        // The user plan said:
        // "Fetch Receipt entities from Core Data. Filter receipts based on the requested period"
        
        // Since I can't change the method signature in the protocol without changing the Mock and the ViewModel call site,
        // I will do that as part of this change.
        
        // Let's assume I will update the protocol in the next step or right now.
        // Actually, I can't easily change the protocol in this single file write if it breaks other things.
        // But I am in AGENTIC mode, so I can do multiple edits.
        
        // Let's write this file with the *intended* signature, and then I'll update the protocol and ViewModel.
        
        // Wait, if I write this file with a different signature than the protocol, it won't compile.
        // So I should write it to conform to the *current* protocol first, or update the protocol first.
        
        // Actually, the best approach is to update the protocol first or simultaneously.
        // But `write_to_file` is for new files.
        
        // I will write this file with a `loadSummary(for range: DateInterval)` method,
        // and also implement `loadCurrentSummary` as a convenience that defaults to this month,
        // so it conforms to the *current* protocol, but allows for the future.
        
        // Actually, the ViewModel *needs* to pass the date.
        // So I will implement `loadSummary(start: Date, end: Date)` and `loadCurrentSummary` will just call it for "this month".
        
        let now = Date()
        let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: now))!
        let endOfMonth = calendar.date(byAdding: DateComponents(month: 1, day: -1), to: startOfMonth)!
        
        return try await loadSummary(start: startOfMonth, end: endOfMonth)
    }
    
    func loadSummary(start: Date, end: Date) async throws -> HomeSummary {
        // 1. Fetch Receipts in range
        let request = Receipt.fetchRequest()
        request.predicate = NSPredicate(format: "date >= %@ AND date <= %@", start as NSDate, end as NSDate)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Receipt.date, ascending: false)]
        
        let receipts = try viewContext.fetch(request)
        
        // 2. Calculate Total Spend
        let totalSpend = receipts.reduce(Decimal(0)) { sum, receipt in sum + Decimal(receipt.totalAmount) }
        
        // 3. Calculate Previous Period Spend
        // We need to fetch previous period data.
        let duration = end.timeIntervalSince(start)
        let prevEnd = start.addingTimeInterval(-1)
        let prevStart = prevEnd.addingTimeInterval(-duration)
        
        let prevRequest = Receipt.fetchRequest()
        prevRequest.predicate = NSPredicate(format: "date >= %@ AND date <= %@", prevStart as NSDate, prevEnd as NSDate)
        let prevReceipts = try viewContext.fetch(prevRequest)
        let prevTotalSpend = prevReceipts.reduce(Decimal(0)) { sum, receipt in sum + Decimal(receipt.totalAmount) }
        
        // 4. Average Daily Spend
        // Avoid division by zero
        let days = max(1, calendar.dateComponents([.day], from: start, to: end).day ?? 1)
        let averageDailySpend = totalSpend / Decimal(days)
        
        // 5. Top Merchant
        let merchantSpending = Dictionary(grouping: receipts, by: { $0.merchantName ?? "Unknown" })
            .mapValues { $0.reduce(Decimal(0)) { sum, receipt in sum + Decimal(receipt.totalAmount) } }
        
        let topMerchant = merchantSpending.max(by: { $0.value < $1.value })
        
        // 6. Top Category & Category Distribution
        // We need to aggregate items if possible, or fallback to receipt category (which we don't strictly have on Receipt, 
        // but we have `merchantCategory` on Receipt, and `category` on ReceiptItem).
        
        var categoryMap: [String: Decimal] = [:]
        
        for receipt in receipts {
            if let items = receipt.items as? Set<ReceiptItem>, !items.isEmpty {
                for item in items {
                    let cat = item.category?.isEmpty == false ? item.category! : "Uncategorized"
                    categoryMap[cat, default: 0] += Decimal(item.subtotal)
                }
            } else {
                // Fallback to merchant category
                let cat = receipt.merchantCategory?.isEmpty == false ? receipt.merchantCategory! : "Uncategorized"
                categoryMap[cat, default: 0] += Decimal(receipt.totalAmount)
            }
        }
        
        let topCategory = categoryMap.max(by: { $0.value < $1.value })
        
        // Sort categories for the chart (top 5 + others)
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
        // We look for the single receipt with the highest totalAmount
        let biggestReceipt = receipts.max(by: { $0.totalAmount < $1.totalAmount })
        let biggestPurchaseData: (amount: Decimal, merchant: String, date: Date)?
        if let biggest = biggestReceipt {
            biggestPurchaseData = (Decimal(biggest.totalAmount), biggest.merchantName ?? "Unknown", biggest.date ?? Date())
        } else {
            biggestPurchaseData = nil
        }
        
        return HomeSummary(
            periodDescription: "", // ViewModel handles this
            totalSpend: totalSpend,
            previousPeriodTotalSpend: prevTotalSpend,
            averageDailySpend: averageDailySpend,
            topMerchantName: topMerchant?.key,
            topMerchantAmount: topMerchant?.value,
            topCategoryName: topCategory?.key,
            topCategoryAmount: topCategory?.value,
            biggestPurchase: biggestPurchaseData,
            categorySpending: finalCategories
        )
    }
}
