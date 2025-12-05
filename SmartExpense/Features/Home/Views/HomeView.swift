import SwiftUI
import Charts

struct HomeView: View {
    @ObservedObject var viewModel: HomeViewModel
    @State private var showingCaptureFlow = false
    @State private var slideEdge: Edge = .trailing
    @State private var dragOffset: CGFloat = 0

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            background
            
            VStack(spacing: 0) {
                // Fixed Header Area
                VStack(spacing: 16) {
                    periodSelector
                    periodDescriptionView
                }
                .padding(.horizontal, 24)
                .padding(.top, 20)
                .padding(.bottom, 10)
                
                // Swipeable Content Area
                mainContentView
                    .id(viewModel.periodTitle) // Force recreation on period change
                    .transition(.asymmetric(
                        insertion: .move(edge: slideEdge),
                        removal: .move(edge: slideEdge == .leading ? .trailing : .leading)
                    ))
            }
            
            captureButton
                .padding(.trailing, 24)
                .padding(.bottom, 40)
        }
        .onAppear {
            viewModel.onAppear()
        }
    }

    private var background: some View {
        LinearGradient(
            colors: [
                Color(.systemBackground),
                Color(.systemGray6).opacity(0.3)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()
    }

    private var periodSelector: some View {
        HStack(spacing: 0) {
            ForEach(HomeViewModel.Period.allCases) { period in
                Button(action: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        viewModel.selectPeriod(period)
                    }
                }) {
                    Text(period.rawValue)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(viewModel.selectedPeriod == period ? .white : .secondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(
                            ZStack {
                                if viewModel.selectedPeriod == period {
                                    Capsule()
                                        .fill(Color.accentColor)
                                        .matchedGeometryEffect(id: "PeriodCursor", in: namespace)
                                }
                            }
                        )
                }
            }
        }
        .padding(4)
        .background(
            Capsule()
                .fill(Color(.systemGray6))
        )
        .frame(maxWidth: .infinity)
    }
    
    @Namespace private var namespace

    private var periodDescriptionView: some View {
        HStack(spacing: 6) {
            Text(viewModel.periodTitle)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.secondary)
                .id("PeriodTitle-\(viewModel.periodTitle)") // Animate text change
                .transition(.opacity)
            
            if viewModel.state == .loading {
                ProgressView()
                    .scaleEffect(0.7)
            }
        }
        .frame(maxWidth: .infinity)
    }
    
    private var mainContentView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                totalSpendView
                cardsGrid
                categoryDistributionChart
                Spacer(minLength: 100)
            }
            .padding(.horizontal, 24)
            .padding(.top, 10)
        }
        .contentShape(Rectangle()) // Ensure the whole area is swipeable
        .gesture(
            DragGesture()
                .onChanged { value in
                    dragOffset = value.translation.width
                }
                .onEnded { value in
                    let threshold: CGFloat = 50
                    if value.translation.width > threshold {
                        // Swipe Right -> Previous Period
                        slideEdge = .leading // Enter from leading (left)
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                            viewModel.movePeriod(by: -1)
                        }
                    } else if value.translation.width < -threshold {
                        // Swipe Left -> Next Period
                        slideEdge = .trailing // Enter from trailing (right)
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                            viewModel.movePeriod(by: 1)
                        }
                    }
                    dragOffset = 0
                }
        )
    }

    private var totalSpendView: some View {
        VStack(spacing: 8) {
            Text(viewModel.totalSpendText)
                .font(.system(size: 48, weight: .bold, design: .rounded))
                .foregroundColor(.primary)
            
            if !viewModel.spendingComparisonText.isEmpty {
                Text(viewModel.spendingComparisonText)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(viewModel.spendingComparisonText.contains("+") ? .red : .green)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(viewModel.spendingComparisonText.contains("+") ? Color.red.opacity(0.1) : Color.green.opacity(0.1))
                    )
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .offset(x: dragOffset) // Visual feedback during drag
    }

    private var cardsGrid: some View {
        HStack(spacing: 16) {
            // Top Category Card
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
                    
                    Text(viewModel.topCategoryTitle.components(separatedBy: " – ").first ?? "-")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.primary)
                        .lineLimit(1)
                    
                    Text(viewModel.topCategoryTitle.components(separatedBy: " – ").last ?? "-")
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
            
            // Biggest Purchase Card
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
                    
                    Text(viewModel.biggestPurchaseAmount)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.primary)
                    
                    Text(viewModel.biggestPurchaseMerchant)
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
        .offset(x: dragOffset)
    }
    
    private var categoryDistributionChart: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Spending by Category")
                .font(.headline)
                .foregroundColor(.primary)
            
            Chart(viewModel.categorySpending, id: \.category) { item in
                SectorMark(
                    angle: .value("Amount", item.amount),
                    innerRadius: .ratio(0.618),
                    angularInset: 1.5
                )
                .cornerRadius(5)
                .foregroundStyle(by: .value("Category", item.category))
            }
            .frame(height: 220)
            .chartLegend(position: .bottom, spacing: 20)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color(.secondarySystemGroupedBackground))
                .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
        )
        .offset(x: dragOffset)
    }

    private var captureButton: some View {
        Button(action: {
            showingCaptureFlow = true
        }) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.accentColor,
                                Color.accentColor.opacity(0.8)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 64, height: 64)
                    .shadow(color: Color.accentColor.opacity(0.4), radius: 20, x: 0, y: 10)
                    .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)

                Image(systemName: "plus")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.white)
            }
        }
        .accessibilityLabel("Capture expense")
        .scaleEffect(1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: false)
        .fullScreenCover(isPresented: $showingCaptureFlow) {
            CaptureCoordinatorView()
        }
    }
}

struct HomeKPICardView: View {
    let title: String
    let value: String
    let subtitle: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(color)
                    .frame(width: 32, height: 32)
                    .background(
                        Circle()
                            .fill(color.opacity(0.15))
                    )
                
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.secondary)
                    .textCase(.uppercase)
                    .tracking(0.5)

                Text(value)
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)

                Text(subtitle)
                    .font(.system(size: 12, weight: .regular))
                    .foregroundColor(.secondary)
            }
        }
        .padding(20)
        .frame(width: 200, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .stroke(
                            LinearGradient(
                                colors: [
                                    color.opacity(0.2),
                                    color.opacity(0.05)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
        )
        .shadow(color: Color.black.opacity(0.06), radius: 16, x: 0, y: 8)
        .shadow(color: Color.black.opacity(0.03), radius: 4, x: 0, y: 2)
    }
}

#Preview {
    HomeView(viewModel: HomeViewModel(service: HomeOverviewMockService()))
}
