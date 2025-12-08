import Foundation
import Combine
import CoreData

@MainActor
final class HomeViewModel: ObservableObject {
    enum Period: String, CaseIterable, Identifiable {
        case weekly = "Weekly"
        case monthly = "Monthly"
        case yearly = "Yearly"
        
        var id: String { rawValue }
    }
    

    
    enum LoadingState: Equatable {
        case idle
        case loading
        case loaded
        case failed(error: String)
        
        static func == (lhs: LoadingState, rhs: LoadingState) -> Bool {
            switch (lhs, rhs) {
            case (.idle, .idle), (.loading, .loading), (.loaded, .loaded):
                return true
            case (.failed(let lhsError), .failed(let rhsError)):
                return lhsError == rhsError
            default:
                return false
            }
        }
    }

    @Published var selectedPeriod: Period = .monthly
    @Published private(set) var currentReferenceDate: Date = Date()
    
    @Published private(set) var state: LoadingState = .idle
    @Published private(set) var periodTitle: String = ""
    @Published private(set) var previousPeriodTitle: String = ""
    @Published private(set) var nextPeriodTitle: String = ""
    @Published private(set) var totalSpendText: String = "-"
    @Published private(set) var spendingComparisonText: String = ""
    @Published private(set) var averageDailySpendText: String = "-"
    @Published private(set) var topMerchantTitle: String = "-"
    @Published private(set) var topCategoryTitle: String = "-"
    
    @Published private(set) var biggestPurchaseAmount: String = "-"
    @Published private(set) var biggestPurchaseMerchant: String = "-"
    @Published private(set) var biggestPurchaseDate: String = "-"
    @Published private(set) var biggestPurchaseReceiptId: NSManagedObjectID?
    
    @Published private(set) var topCategoryNameOnly: String?
    @Published private(set) var currentDateRange: (start: Date, end: Date)?
    
    @Published private(set) var categorySpending: [(category: String, amount: Double)] = []
    @Published private(set) var spendingTrend: [(date: Date, amount: Double)] = []

    private let service: HomeOverviewServiceProtocol
    private let currencyFormatter: NumberFormatter
    private let calendar = Calendar.current

    init(service: HomeOverviewServiceProtocol,
         currencyFormatter: NumberFormatter = HomeViewModel.defaultCurrencyFormatter()) {
        self.service = service
        self.currencyFormatter = currencyFormatter
        
        // Initialize period title
        updatePeriodTitle()
    }

    func onAppear() {
        // Set currentDateRange immediately so it's available for navigation
        currentDateRange = dateRange(for: selectedPeriod, date: currentReferenceDate)
        
        Task { await load() }
    }

    func refresh() {
        Task { await load() }
    }
    
    func selectPeriod(_ period: Period) {
        guard selectedPeriod != period else { return }
        selectedPeriod = period
        currentDateRange = dateRange(for: selectedPeriod, date: currentReferenceDate)
        updatePeriodTitle()
        Task { await load() }
    }
    
    func movePeriod(by value: Int) {
        guard let newDate = calendar.date(byAdding: component(for: selectedPeriod), value: value, to: currentReferenceDate) else { return }
        currentReferenceDate = newDate
        currentDateRange = dateRange(for: selectedPeriod, date: currentReferenceDate)
        updatePeriodTitle()
        Task { await load() }
    }

    private func load() async {
        state = .loading
        do {
            let range = dateRange(for: selectedPeriod, date: currentReferenceDate)
            currentDateRange = range
            let homePeriod = mapPeriod(selectedPeriod)
            
            let summary = try await service.loadSummary(start: range.start, end: range.end, period: homePeriod)
            
            apply(summary: summary)
            state = .loaded
        } catch {
            state = .failed(error: "Unable to load overview. Please try again.")
        }
    }
    
    private func mapPeriod(_ period: Period) -> HomePeriod {
        switch period {
        case .weekly: return .weekly
        case .monthly: return .monthly
        case .yearly: return .yearly
        }
    }
    
    private func dateRange(for period: Period, date: Date) -> (start: Date, end: Date) {
        let calendar = Calendar.current
        var start: Date
        var end: Date
        
        switch period {
        case .weekly:
            let components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: date)
            start = calendar.date(from: components)!
            end = calendar.date(byAdding: .weekOfYear, value: 1, to: start)!.addingTimeInterval(-1)
        case .monthly:
            let components = calendar.dateComponents([.year, .month], from: date)
            start = calendar.date(from: components)!
            end = calendar.date(byAdding: .month, value: 1, to: start)!.addingTimeInterval(-1)
        case .yearly:
            let components = calendar.dateComponents([.year], from: date)
            start = calendar.date(from: components)!
            end = calendar.date(byAdding: .year, value: 1, to: start)!.addingTimeInterval(-1)
        }
        
        return (start, end)
    }

    private func apply(summary: HomeSummary) {
        // We override the period title from the summary with our own calculated one
        updatePeriodTitle()
        
        totalSpendText = currencyFormatter.string(from: summary.totalSpend as NSDecimalNumber) ?? "-"
        
        if let previousTotal = summary.previousPeriodTotalSpend {
            let diff = summary.totalSpend - previousTotal
            let diffText = currencyFormatter.string(from: abs(diff) as NSDecimalNumber) ?? "-"
            let sign = diff >= 0 ? "+" : "-"
            spendingComparisonText = "\(sign)\(diffText) vs last period"
        } else {
            spendingComparisonText = ""
        }
        
        averageDailySpendText = currencyFormatter.string(from: summary.averageDailySpend as NSDecimalNumber) ?? "-"

        if let merchantName = summary.topMerchantName,
           let amount = summary.topMerchantAmount,
           let amountText = currencyFormatter.string(from: amount as NSDecimalNumber) {
            topMerchantTitle = "\(merchantName) – \(amountText)"
        } else {
            topMerchantTitle = "No merchant data yet"
        }

        if let categoryName = summary.topCategoryName,
           let amount = summary.topCategoryAmount,
           let amountText = currencyFormatter.string(from: amount as NSDecimalNumber) {
            topCategoryTitle = "\(categoryName) – \(amountText)"
            topCategoryNameOnly = categoryName
        } else {
            topCategoryTitle = "No category data yet"
            topCategoryNameOnly = nil
        }
        
        if let biggest = summary.biggestPurchase {
            biggestPurchaseAmount = currencyFormatter.string(from: biggest.amount as NSDecimalNumber) ?? "-"
            biggestPurchaseMerchant = biggest.merchant
            biggestPurchaseReceiptId = summary.biggestPurchaseReceiptId
            
            let dateFormatter = DateFormatter()
            dateFormatter.dateStyle = .medium
            biggestPurchaseDate = dateFormatter.string(from: biggest.date)
        } else {
            biggestPurchaseAmount = "-"
            biggestPurchaseMerchant = "-"
            biggestPurchaseDate = "-"
            biggestPurchaseReceiptId = nil
        }
        
        categorySpending = summary.categorySpending.map { ($0.category, NSDecimalNumber(decimal: $0.amount).doubleValue) }
        spendingTrend = summary.spendingTrend.map { ($0.date, NSDecimalNumber(decimal: $0.amount).doubleValue) }
    }
    
    private func updatePeriodTitle() {
        periodTitle = title(for: selectedPeriod, date: currentReferenceDate)
        
        if let prevDate = calendar.date(byAdding: component(for: selectedPeriod), value: -1, to: currentReferenceDate) {
            previousPeriodTitle = title(for: selectedPeriod, date: prevDate)
        } else {
            previousPeriodTitle = ""
        }
        
        if let nextDate = calendar.date(byAdding: component(for: selectedPeriod), value: 1, to: currentReferenceDate) {
            nextPeriodTitle = title(for: selectedPeriod, date: nextDate)
        } else {
            nextPeriodTitle = ""
        }
    }
    
    private func title(for period: Period, date: Date) -> String {
        let formatter = DateFormatter()
        
        switch period {
        case .weekly:
            // Show "Oct 22 - Oct 28"
            // Find start and end of week
            if let weekInterval = calendar.dateInterval(of: .weekOfYear, for: date) {
                formatter.dateFormat = "MMM d"
                let start = formatter.string(from: weekInterval.start)
                let end = formatter.string(from: weekInterval.end.addingTimeInterval(-1))
                return "\(start) - \(end)"
            } else {
                return "This Week"
            }
        case .monthly:
            formatter.dateFormat = "MMM yyyy"
            return formatter.string(from: date)
        case .yearly:
            formatter.dateFormat = "yyyy"
            return formatter.string(from: date)
        }
    }
    
    private func component(for period: Period) -> Calendar.Component {
        switch period {
        case .weekly: return .weekOfYear
        case .monthly: return .month
        case .yearly: return .year
        }
    }

    nonisolated private static func defaultCurrencyFormatter() -> NumberFormatter {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.maximumFractionDigits = 2
        return formatter
    }
}


