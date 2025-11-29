import Foundation
import Combine

@MainActor
final class HomeViewModel: ObservableObject {
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

    @Published private(set) var state: LoadingState = .idle
    @Published private(set) var periodTitle: String = ""
    @Published private(set) var totalSpendText: String = "-"
    @Published private(set) var averageDailySpendText: String = "-"
    @Published private(set) var topMerchantTitle: String = "-"
    @Published private(set) var topCategoryTitle: String = "-"

    private let service: HomeOverviewServiceProtocol
    private let currencyFormatter: NumberFormatter

    init(service: HomeOverviewServiceProtocol,
         currencyFormatter: NumberFormatter = HomeViewModel.defaultCurrencyFormatter()) {
        self.service = service
        self.currencyFormatter = currencyFormatter
    }

    func onAppear() {
        guard case .idle = state else { return }
        Task {
            await load()
        }
    }

    func refresh() {
        Task {
            await load()
        }
    }

    private func load() async {
        state = .loading
        do {
            let summary = try await service.loadCurrentSummary()
            apply(summary: summary)
            state = .loaded
        } catch {
            state = .failed(error: "Unable to load overview. Please try again.")
        }
    }

    private func apply(summary: HomeSummary) {
        periodTitle = summary.periodDescription
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

    nonisolated private static func defaultCurrencyFormatter() -> NumberFormatter {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.maximumFractionDigits = 2
        return formatter
    }
}


