import SwiftUI
import Charts
import CoreData

struct HomeContentPage: View {
    let date: Date
    @ObservedObject var viewModel: HomeViewModel
    @Binding var historyFilter: HistoryFilter?
    
    // Local state for interacting with charts
    @State private var selectedCategory: String?
    
    // Derived data from ViewModel cache
    private var data: HomeViewModel.PageData {
        // Find normalized date key that matches
        // We rely on ViewModel to normalize consistency, or we normalize here.
        // Ideally we assume 'date' passed in is already a valid key from availableDates
        viewModel.pageData[date] ?? .empty
    }

    // Access to ManagedObjectContext if needed for lazy loading entities (e.g. Receipt)
    @Environment(\.managedObjectContext) private var viewContext

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                totalSpendView
                cardsGrid
                spendingTrendChart
                categoryDistributionChart
                Spacer(minLength: 100)
            }
            .padding(.horizontal, 24)
            .padding(.top, 10)
        }
        .task {
            // Trigger load when this page appears (standard TabView behavior)
            await viewModel.load(for: date)
        }
    }

    private var totalSpendView: some View {
        VStack(spacing: 8) {
            Text(data.totalSpendText)
                .font(.system(size: 48, weight: .bold, design: .rounded))
                .foregroundColor(.primary)
            
            if !data.spendingComparisonText.isEmpty {
                Text(data.spendingComparisonText)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(data.spendingComparisonText.contains("+") ? .red : .green)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(data.spendingComparisonText.contains("+") ? Color.red.opacity(0.1) : Color.green.opacity(0.1))
                    )
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
    }

    private var cardsGrid: some View {
        HStack(spacing: 16) {
            // Top Category Card
            Button(action: {
                if let category = data.topCategoryNameOnly {
                    let range = viewModel.dateRange(for: viewModel.selectedPeriod, date: date)
                    historyFilter = HistoryFilter(
                        category: category,
                        dateRange: (start: range.start, end: range.end),
                        receiptId: nil
                    )
                }
            }) {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "tag.fill")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.purple)
                            .frame(width: 32, height: 32)
                            .background(Circle().fill(Color.purple.opacity(0.15)))
                        Spacer()
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Top Category")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.secondary)
                            .textCase(.uppercase)
                        
                        Text(data.topCategoryTitle.components(separatedBy: " – ").first ?? "-")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.primary)
                            .lineLimit(1)
                        
                        Text(data.topCategoryTitle.components(separatedBy: " – ").last ?? "-")
                            .font(.system(size: 14, weight: .regular))
                            .foregroundColor(.secondary)
                    }
                }
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(Color(.secondarySystemGroupedBackground))
                        .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
                )
            }
            .buttonStyle(PlainButtonStyle())
            .disabled(data.topCategoryNameOnly == nil)
            
            // Biggest Purchase Card
            if let receiptId = data.biggestPurchaseReceiptId,
               let receipt = try? viewContext.existingObject(with: receiptId) as? Receipt {
                NavigationLink(destination: ExpenseDetailView(receipt: receipt, onDateChanged: nil)) {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "cart.fill")
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundColor(.orange)
                                .frame(width: 32, height: 32)
                                .background(Circle().fill(Color.orange.opacity(0.15)))
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.secondary.opacity(0.5))
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Biggest Purchase")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.secondary)
                                .textCase(.uppercase)
                            
                            Text(data.biggestPurchaseAmount)
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.primary)
                            
                            Text(data.biggestPurchaseMerchant)
                                .font(.system(size: 14, weight: .regular))
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                        }
                    }
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .fill(Color(.secondarySystemGroupedBackground))
                            .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
                    )
                }
                .buttonStyle(PlainButtonStyle())
            } else {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "cart.fill")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.orange)
                            .frame(width: 32, height: 32)
                            .background(Circle().fill(Color.orange.opacity(0.15)))
                        Spacer()
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Biggest Purchase")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.secondary)
                            .textCase(.uppercase)
                        
                        Text(data.biggestPurchaseAmount)
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.primary)
                        
                        Text(data.biggestPurchaseMerchant)
                            .font(.system(size: 14, weight: .regular))
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                }
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(Color(.secondarySystemGroupedBackground))
                        .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
                )
            }
        }
    }
    
    private var categoryDistributionChart: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Spending by Category")
                .font(.headline)
                .foregroundColor(.primary)
            
            Chart(data.categorySpending, id: \.category) { item in
                SectorMark(
                    angle: .value("Amount", item.amount),
                    innerRadius: .ratio(0.618),
                    angularInset: 1.5
                )
                .cornerRadius(5)
                .foregroundStyle(by: .value("Category", item.category))
                .opacity(selectedCategory == nil || selectedCategory == item.category ? 1.0 : 0.3)
                .annotation(position: .overlay) {
                    VStack(spacing: 2) {
                        Text(item.category)
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(.white)
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                        
                        Text("$\(Int(item.amount))")
                            .font(.system(size: 9, weight: .medium))
                            .foregroundColor(.white.opacity(0.9))
                    }
                    .padding(4)
                }
            }
            .frame(height: 220)
            .chartAngleSelection(value: $selectedCategory)
            .chartBackground { chartProxy in
                GeometryReader { geometry in
                    if let selectedCategory = selectedCategory,
                       let selectedItem = data.categorySpending.first(where: { $0.category == selectedCategory }) {
                        VStack(spacing: 4) {
                            Text(selectedItem.category)
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.primary)
                            
                            Text("$\(Int(selectedItem.amount))")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.secondary)
                        }
                        .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
                    }
                }
            }
            .chartLegend(.hidden)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color(.secondarySystemGroupedBackground))
                .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
        )
    }

    private var spendingTrendChart: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Spending Trend")
                .font(.headline)
                .foregroundColor(.primary)
            
            if viewModel.selectedPeriod == .yearly {
                Text("Trend not available for yearly view")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, minHeight: 200)
            } else {
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        ScrollView(.horizontal, showsIndicators: false) {
                            Chart(data.spendingTrend, id: \.date) { item in
                                BarMark(
                                    x: .value("Date", item.date),
                                    y: .value("Amount", item.amount),
                                    width: .fixed(40)
                                )
                                .cornerRadius(8)
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [
                                            Color.accentColor,
                                            Color.accentColor.opacity(0.7)
                                        ],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )
                                .annotation(position: .top, alignment: .center) {
                                    if item.amount > 0 {
                                        Text("$\(Int(item.amount))")
                                            .font(.system(size: 11, weight: .semibold))
                                            .foregroundColor(.secondary)
                                    }
                                }
                            }
                            .frame(width: max(geometry.size.width, CGFloat(data.spendingTrend.count) * 60))
                            .frame(height: 220)
                            .chartXAxis {
                                AxisMarks(values: .automatic) { value in
                                    AxisGridLine()
                                    AxisTick()
                                    if viewModel.selectedPeriod == .monthly {
                                        AxisValueLabel(format: .dateTime.month())
                                    } else if viewModel.selectedPeriod == .weekly {
                                        AxisValueLabel(format: .dateTime.month().day())
                                    }
                                }
                            }
                            .chartYAxis {
                                AxisMarks(position: .leading)
                            }
                            .defaultScrollAnchor(.trailing)
                        }
                        
                        // Left fade indicator
                        LinearGradient(
                            colors: [
                                Color(.secondarySystemGroupedBackground),
                                Color(.secondarySystemGroupedBackground).opacity(0)
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                        .frame(width: 20)
                        .allowsHitTesting(false)
                        
                        // Right fade indicator
                        LinearGradient(
                            colors: [
                                Color(.secondarySystemGroupedBackground).opacity(0),
                                Color(.secondarySystemGroupedBackground)
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                        .frame(width: 20)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                        .allowsHitTesting(false)
                    }
                }
                .frame(height: 220)
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color(.secondarySystemGroupedBackground))
                .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
        )
    }
}
