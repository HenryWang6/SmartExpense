import Foundation
import Combine

@MainActor
final class HomeViewModel: ObservableObject {
    enum Period: String, CaseIterable, Identifiable {
        case daily = "Daily"
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
    @Published private(set) var totalSpendText: String = "-"
    @Published private(set) var averageDailySpendText: String = "-"
    @Published private(set) var topMerchantTitle: String = "-"
    @Published private(set) var topCategoryTitle: String = "-"

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
        if case .idle = state {
            Task { await load() }
        }
    }

    func refresh() {
        Task { await load() }
    }
    
    func selectPeriod(_ period: Period) {
        guard selectedPeriod != period else { return }
        selectedPeriod = period
        // Reset reference date to today when switching periods? 
        // Or keep the same reference date? Usually resetting to "now" or keeping the anchor is better.
        // Let's keep the current reference date but snap it if necessary.
        // For simplicity, let's just keep the currentReferenceDate as is, 
        // but we might want to ensure it's valid for the period.
        updatePeriodTitle()
        Task { await load() }
    }
    
    func movePeriod(by value: Int) {
        guard let newDate = calendar.date(byAdding: component(for: selectedPeriod), value: value, to: currentReferenceDate) else { return }
        currentReferenceDate = newDate
        updatePeriodTitle()
        Task { await load() }
    }

    private func load() async {
        state = .loading
        do {
            // In a real app, we would pass the date range to the service
            // let range = dateRange(for: selectedPeriod, date: currentReferenceDate)
            // let summary = try await service.loadSummary(for: range)
            
            // For now, we just load the mock summary
            let summary = try await service.loadCurrentSummary()
            apply(summary: summary)
            state = .loaded
        } catch {
            state = .failed(error: "Unable to load overview. Please try again.")
        }
    }

    private func apply(summary: HomeSummary) {
        // We override the period title from the summary with our own calculated one
        updatePeriodTitle()
        
        totalSpendText = currencyFormatter.string(from: summary.totalSpend as NSDecimalNumber) ?? "-"
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
        } else {
            topCategoryTitle = "No category data yet"
        }
    }
    
    private func updatePeriodTitle() {
        let formatter = DateFormatter()
        
        switch selectedPeriod {
        case .daily:
            if calendar.isDateInToday(currentReferenceDate) {
                periodTitle = "Today"
            } else if calendar.isDateInYesterday(currentReferenceDate) {
                periodTitle = "Yesterday"
            } else {
                formatter.dateStyle = .medium
                periodTitle = formatter.string(from: currentReferenceDate)
            }
        case .weekly:
            // Show "Oct 22 - Oct 28"
            // Find start and end of week
            if let weekInterval = calendar.dateInterval(of: .weekOfYear, for: currentReferenceDate) {
                formatter.dateFormat = "MMM d"
                let start = formatter.string(from: weekInterval.start)
                let end = formatter.string(from: weekInterval.end.addingTimeInterval(-1))
                periodTitle = "\(start) - \(end)"
            } else {
                periodTitle = "This Week"
            }
        case .monthly:
            formatter.dateFormat = "MMMM yyyy"
            periodTitle = formatter.string(from: currentReferenceDate)
        case .yearly:
            formatter.dateFormat = "yyyy"
            periodTitle = formatter.string(from: currentReferenceDate)
        }
    }
    
    private func component(for period: Period) -> Calendar.Component {
        switch period {
        case .daily: return .day
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


