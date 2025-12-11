import Foundation
import Combine
import CoreData

@MainActor
final class HomeViewModel: ObservableObject {
    enum Period: String, CaseIterable, Identifiable {
        case weekly = "Week"
        case monthly = "Month"
        case yearly = "Year"
        
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
    @Published private(set) var availableDates: [Date] = []
    @Published private(set) var currentDateRange: (start: Date, end: Date)?
    
    // Add public access to format titles for the view
    func title(for date: Date) -> String {
        return title(for: selectedPeriod, date: date)
    }
    struct PageData: Equatable {
        let totalSpendText: String
        let spendingComparisonText: String
        let averageDailySpendText: String
        let topMerchantTitle: String
        let topCategoryTitle: String
        let biggestPurchaseAmount: String
        let biggestPurchaseMerchant: String
        let biggestPurchaseDate: String
        let biggestPurchaseReceiptId: NSManagedObjectID?
        let topCategoryNameOnly: String?
        let categorySpending: [(category: String, amount: Double, color: String?, icon: String?)]
        let spendingTrend: [(date: Date, amount: Double)]
        
        static let empty = PageData(
            totalSpendText: "-", spendingComparisonText: "", averageDailySpendText: "-",
            topMerchantTitle: "-", topCategoryTitle: "-",
            biggestPurchaseAmount: "-", biggestPurchaseMerchant: "-", biggestPurchaseDate: "-",
            biggestPurchaseReceiptId: nil, topCategoryNameOnly: nil,
            categorySpending: [], spendingTrend: []
        )
        
        static func == (lhs: PageData, rhs: PageData) -> Bool {
            return lhs.totalSpendText == rhs.totalSpendText &&
                lhs.spendingComparisonText == rhs.spendingComparisonText &&
                lhs.averageDailySpendText == rhs.averageDailySpendText &&
                lhs.topMerchantTitle == rhs.topMerchantTitle &&
                lhs.topCategoryTitle == rhs.topCategoryTitle &&
                lhs.biggestPurchaseAmount == rhs.biggestPurchaseAmount &&
                lhs.biggestPurchaseMerchant == rhs.biggestPurchaseMerchant &&
                lhs.biggestPurchaseDate == rhs.biggestPurchaseDate &&
                lhs.biggestPurchaseReceiptId == rhs.biggestPurchaseReceiptId &&
                lhs.topCategoryNameOnly == rhs.topCategoryNameOnly &&
                lhs.categorySpending.map { $0.category } == rhs.categorySpending.map { $0.category } &&
                lhs.categorySpending.map { $0.amount } == rhs.categorySpending.map { $0.amount } &&
                lhs.categorySpending.map { $0.color } == rhs.categorySpending.map { $0.color } &&
                lhs.categorySpending.map { $0.icon } == rhs.categorySpending.map { $0.icon } &&
                lhs.spendingTrend.map { $0.date } == rhs.spendingTrend.map { $0.date } &&
                lhs.spendingTrend.map { $0.amount } == rhs.spendingTrend.map { $0.amount }
        }
    }

    @Published var pageData: [Date: PageData] = [:]
    
    // Properties for legacy support / current view convenience
    // They now forward to the current reference date's data
    var currentData: PageData {
        pageData[normalize(currentReferenceDate, for: selectedPeriod)] ?? .empty
    }

    // Proxy properties pointing to currentData
    var totalSpendText: String { currentData.totalSpendText }
    var spendingComparisonText: String { currentData.spendingComparisonText }
    var topCategoryNameOnly: String? { currentData.topCategoryNameOnly }
    var topCategoryTitle: String { currentData.topCategoryTitle }
    var biggestPurchaseReceiptId: NSManagedObjectID? { currentData.biggestPurchaseReceiptId }
    var biggestPurchaseAmount: String { currentData.biggestPurchaseAmount }
    var biggestPurchaseMerchant: String { currentData.biggestPurchaseMerchant }
    var categorySpending: [(category: String, amount: Double, color: String?, icon: String?)] { currentData.categorySpending }
    var spendingTrend: [(date: Date, amount: Double)] { currentData.spendingTrend }


    private let service: HomeOverviewServiceProtocol
    private let currencyFormatter: NumberFormatter
    private let calendar = Calendar.current

    private var cancellables = Set<AnyCancellable>()
    
    init(service: HomeOverviewServiceProtocol,
         currencyFormatter: NumberFormatter = HomeViewModel.defaultCurrencyFormatter()) {
        self.service = service
        self.currencyFormatter = currencyFormatter
        
        // Initialize available dates (current + past 24 periods)
        generateAvailableDates()
        
        // Initialize period title and date range immediately so they're available for navigation
        updatePeriodTitle()
        currentDateRange = dateRange(for: selectedPeriod, date: currentReferenceDate)
        
        // Subscribe to receipt saved notification
        NotificationCenter.default.publisher(for: .receiptSaved)
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.refresh()
            }
            .store(in: &cancellables)
            
        // Subscribe to category updates
        NotificationCenter.default.publisher(for: .categoryUpdated)
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.refresh()
            }
            .store(in: &cancellables)
    }

    func onAppear() {
        // Set currentDateRange immediately so it's available for navigation
        currentDateRange = dateRange(for: selectedPeriod, date: currentReferenceDate)
        
        Task { await load(for: currentReferenceDate) }
    }

    func refresh() {
        // Clear cache and reload current
        pageData.removeAll()
        Task { await load(for: currentReferenceDate) }
    }
    
    func selectPeriod(_ period: Period) {
        if selectedPeriod == period {
            // If tapping the same period, check if we need to reset to current
            let current = Date()
            let normalizedCurrent = normalize(current, for: period)
            
            // If we are not already at the current reference date (normalized), reset
            if currentReferenceDate != normalizedCurrent {
               currentReferenceDate = normalizedCurrent
               
               // We might need to regenerate available dates if the range shifted significantly,
               // but usually availableDates covers "now". 
               // Just to be safe and consistent with generateAvailableDates logic which puts current at end:
               generateAvailableDates() 
               
               currentDateRange = dateRange(for: selectedPeriod, date: currentReferenceDate)
               updatePeriodTitle()
               Task { await load(for: currentReferenceDate) }
            }
            return
        }
        
        selectedPeriod = period
        
        // Regenerate available dates for the new period type
        // Reset to "current" (last in list) when switching period types
        // to avoid confusion or mapping errors
        currentReferenceDate = Date()
        generateAvailableDates()
        
        currentDateRange = dateRange(for: selectedPeriod, date: currentReferenceDate)
        updatePeriodTitle()
        Task { await load(for: currentReferenceDate) }
    }
    

    
    // Helper to generate a fixed list of dates (e.g. Current + Past 24 periods)
    private func generateAvailableDates() {
        var dates: [Date] = []
        let count = 24 // Past 24 periods
        let component = self.component(for: selectedPeriod)
        
        // Generate from past to current, so current is at end
        for i in (0...count).reversed() {
            if let date = calendar.date(byAdding: component, value: -i, to: Date()) {
                // Normalize date to start of period to ensure consistency
                let normalized = normalize(date, for: selectedPeriod)
                dates.append(normalized)
            }
        }
        self.availableDates = dates
        
        // Ensure currentReferenceDate is one of the available dates (snap to closest or last)
        let normalizedCurrent = normalize(currentReferenceDate, for: selectedPeriod)
        if !dates.contains(normalizedCurrent) {
            // Default to the last one (most current)
            if let last = dates.last {
                currentReferenceDate = last
            }
        } else {
            currentReferenceDate = normalizedCurrent
        }
    }
    
    private func normalize(_ date: Date, for period: Period) -> Date {
        switch period {
        case .weekly:
            return calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: date)) ?? date
        case .monthly:
            return calendar.date(from: calendar.dateComponents([.year, .month], from: date)) ?? date
        case .yearly:
            return calendar.date(from: calendar.dateComponents([.year], from: date)) ?? date
        }
    }
    
    func movePeriod(by value: Int) {
        guard let newDate = calendar.date(byAdding: component(for: selectedPeriod), value: value, to: currentReferenceDate) else { return }
        currentReferenceDate = newDate
        currentDateRange = dateRange(for: selectedPeriod, date: currentReferenceDate)
        updatePeriodTitle()
        Task { await load(for: currentReferenceDate) }
    }
    
    func selectDate(_ date: Date) {
        guard currentReferenceDate != date else { return }
        currentReferenceDate = date
        currentDateRange = dateRange(for: selectedPeriod, date: currentReferenceDate)
        updatePeriodTitle()
        // We don't necessarily need to force load here if the view handles it via onAppear,
        // but it's safe to trigger it.
        Task { await load(for: date) }
    }

    func load(for date: Date) async {
        let normalizedDate = normalize(date, for: selectedPeriod)
        
        // Return if already loaded
        if pageData[normalizedDate] != nil {
            return
        }
        
        // Update global state if this is the current date
        if normalizedDate == normalize(currentReferenceDate, for: selectedPeriod) {
            state = .loading
        }
        
        do {
            let range = dateRange(for: selectedPeriod, date: normalizedDate)
            let homePeriod = mapPeriod(selectedPeriod)
            
            let summary = try await service.loadSummary(start: range.start, end: range.end, period: homePeriod)
            
            let data = process(summary: summary)
            pageData[normalizedDate] = data
            
            if normalizedDate == normalize(currentReferenceDate, for: selectedPeriod) {
                state = .loaded
            }
        } catch {
            if normalizedDate == normalize(currentReferenceDate, for: selectedPeriod) {
                state = .failed(error: "Unable to load overview. Please try again.")
            }
        }
    }
    
    private func mapPeriod(_ period: Period) -> HomePeriod {
        switch period {
        case .weekly: return .weekly
        case .monthly: return .monthly
        case .yearly: return .yearly
        }
    }
    
    func dateRange(for period: Period, date: Date) -> (start: Date, end: Date) {
        let calendar = Calendar.current
        var start: Date
        var end: Date
        
        // Default fallbacks to prevent crashes if date math fails
        let fallbackStart = date
        let fallbackEnd = date

        switch period {
        case .weekly:
            let components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: date)
            start = calendar.date(from: components) ?? fallbackStart
            end = calendar.date(byAdding: .weekOfYear, value: 1, to: start)?.addingTimeInterval(-1) ?? fallbackEnd
        case .monthly:
            let components = calendar.dateComponents([.year, .month], from: date)
            start = calendar.date(from: components) ?? fallbackStart
            end = calendar.date(byAdding: .month, value: 1, to: start)?.addingTimeInterval(-1) ?? fallbackEnd
        case .yearly:
            let components = calendar.dateComponents([.year], from: date)
            start = calendar.date(from: components) ?? fallbackStart
            end = calendar.date(byAdding: .year, value: 1, to: start)?.addingTimeInterval(-1) ?? fallbackEnd
        }
        
        return (start, end)
    }

    private func process(summary: HomeSummary) -> PageData {
        let totalSpendText = currencyFormatter.string(from: summary.totalSpend as NSDecimalNumber) ?? "-"
        
        let spendingComparisonText: String
        if let previousTotal = summary.previousPeriodTotalSpend {
            let diff = summary.totalSpend - previousTotal
            let diffText = currencyFormatter.string(from: abs(diff) as NSDecimalNumber) ?? "-"
            let sign = diff >= 0 ? "+" : "-"
            spendingComparisonText = "\(sign)\(diffText) vs last period"
        } else {
            spendingComparisonText = ""
        }
        
        let averageDailySpendText = currencyFormatter.string(from: summary.averageDailySpend as NSDecimalNumber) ?? "-"

        let topMerchantTitle: String
        if let merchantName = summary.topMerchantName,
           let amount = summary.topMerchantAmount,
           let amountText = currencyFormatter.string(from: amount as NSDecimalNumber) {
            topMerchantTitle = "\(merchantName) – \(amountText)"
        } else {
            topMerchantTitle = "No merchant data yet"
        }

        let topCategoryTitle: String
        let topCategoryNameOnly: String?
        if let categoryName = summary.topCategoryName,
           let amount = summary.topCategoryAmount,
           let amountText = currencyFormatter.string(from: amount as NSDecimalNumber) {
            topCategoryTitle = "\(categoryName) – \(amountText)"
            topCategoryNameOnly = categoryName
        } else {
            topCategoryTitle = "No category data yet"
            topCategoryNameOnly = nil
        }
        
        let biggestPurchaseAmount: String
        let biggestPurchaseMerchant: String
        let biggestPurchaseDate: String
        let biggestPurchaseReceiptId: NSManagedObjectID?
        
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
        
        let categorySpending = summary.categorySpending.map { ($0.category, NSDecimalNumber(decimal: $0.amount).doubleValue, $0.colorHex, $0.icon) }
        let spendingTrend = summary.spendingTrend.map { ($0.date, NSDecimalNumber(decimal: $0.amount).doubleValue) }
        
        return PageData(
            totalSpendText: totalSpendText,
            spendingComparisonText: spendingComparisonText,
            averageDailySpendText: averageDailySpendText,
            topMerchantTitle: topMerchantTitle,
            topCategoryTitle: topCategoryTitle,
            biggestPurchaseAmount: biggestPurchaseAmount,
            biggestPurchaseMerchant: biggestPurchaseMerchant,
            biggestPurchaseDate: biggestPurchaseDate,
            biggestPurchaseReceiptId: biggestPurchaseReceiptId,
            topCategoryNameOnly: topCategoryNameOnly,
            categorySpending: categorySpending,
            spendingTrend: spendingTrend
        )
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


