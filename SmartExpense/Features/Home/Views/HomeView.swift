import SwiftUI
import Charts
import CoreData

struct HomeView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @ObservedObject var viewModel: HomeViewModel
    @State private var showingCaptureFlow = false
    @State private var historyFilter: HistoryFilter?
    @State private var selectedCategory: String?
    @State private var dragOffset: CGFloat = 0
    @State private var contentOpacity: Double = 1.0

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottomTrailing) {
                background
                
                VStack(spacing: 0) {
                    // Fixed Header Area - Only Period Selector
                    periodSelector
                        .padding(.horizontal, 24)
                        .padding(.top, 20)
                        .padding(.bottom, 10)
                    
                    // Swipeable Content Area - Period Description + All Content
                    swipeableContentArea
                        .id(viewModel.periodTitle) // Force recreation on period change
                        .transition(.opacity)
                }
                
                captureButton
                    .padding(.trailing, 24)
                    .padding(.bottom, 40)
            }
            .onAppear {
                viewModel.onAppear()
            }
            .sheet(item: $historyFilter) { filter in
                HistoryView(filter: filter)
            }
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
        GeometryReader { geometry in
            ZStack {
                // Previous Period - rotating in from left
                Text(viewModel.previousPeriodTitle)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                    .id("PrevPeriod-\(viewModel.previousPeriodTitle)")
                    .rotation3DEffect(
                        .degrees(calculatePreviousRotation(dragOffset: dragOffset, width: geometry.size.width)),
                        axis: (x: 0, y: 1, z: 0),
                        anchor: .center,
                        perspective: 0.5
                    )
                    .scaleEffect(calculatePreviousScale(dragOffset: dragOffset, width: geometry.size.width))
                    .opacity(calculatePreviousPeriodOpacity(dragOffset: dragOffset, width: geometry.size.width))
                    .offset(x: calculatePreviousOffset(dragOffset: dragOffset, width: geometry.size.width))
                
                // Current Period - at center focal point
                HStack(spacing: 6) {
                    Text(viewModel.periodTitle)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                        .fixedSize()
                        .id("PeriodTitle-\(viewModel.periodTitle)")
                    
                    if viewModel.state == .loading {
                        ProgressView()
                            .scaleEffect(0.7)
                    }
                }
                .rotation3DEffect(
                    .degrees(calculateCurrentRotation(dragOffset: dragOffset, width: geometry.size.width)),
                    axis: (x: 0, y: 1, z: 0),
                    anchor: .center,
                    perspective: 0.5
                )
                .scaleEffect(calculateCurrentScale(dragOffset: dragOffset, width: geometry.size.width))
                .opacity(calculateCurrentPeriodOpacity(dragOffset: dragOffset, width: geometry.size.width))
                
                // Next Period - rotating in from right
                Text(viewModel.nextPeriodTitle)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                    .id("NextPeriod-\(viewModel.nextPeriodTitle)")
                    .rotation3DEffect(
                        .degrees(calculateNextRotation(dragOffset: dragOffset, width: geometry.size.width)),
                        axis: (x: 0, y: 1, z: 0),
                        anchor: .center,
                        perspective: 0.5
                    )
                    .scaleEffect(calculateNextScale(dragOffset: dragOffset, width: geometry.size.width))
                    .opacity(calculateNextPeriodOpacity(dragOffset: dragOffset, width: geometry.size.width))
                    .offset(x: calculateNextOffset(dragOffset: dragOffset, width: geometry.size.width))
            }
            .frame(maxWidth: .infinity)
        }
        .frame(height: 24)
    }
    
    // MARK: - Previous Period Calculations
    
    private func calculatePreviousRotation(dragOffset: CGFloat, width: CGFloat) -> Double {
        guard width > 0 else { return -60.0 }
        let ratio = Double(dragOffset / width)
        // Rotate from -60° (hidden left) to 0° (center)
        return -60.0 + (ratio * 60.0)
    }
    
    private func calculatePreviousScale(dragOffset: CGFloat, width: CGFloat) -> Double {
        guard width > 0 else { return 0.7 }
        let ratio = Double(dragOffset / width)
        // Scale from 0.7 to 1.0 as it approaches center
        return 0.7 + (ratio * 0.3)
    }
    
    private func calculatePreviousOffset(dragOffset: CGFloat, width: CGFloat) -> CGFloat {
        guard width > 0 else { return 0 }
        let ratio = dragOffset / width
        // Move from left (-width/3) toward center (0)
        return -(width / 3) * (1 - ratio)
    }
    
    private func calculatePreviousPeriodOpacity(dragOffset: CGFloat, width: CGFloat) -> Double {
        guard width > 0 else { return 0.0 }
        if dragOffset > 0 {
            let ratio = Double(dragOffset / width)
            // Fade in from 0 to 1 as it approaches center
            return min(1.0, ratio * 3.0)
        }
        return 0.0
    }
    
    // MARK: - Current Period Calculations
    
    private func calculateCurrentRotation(dragOffset: CGFloat, width: CGFloat) -> Double {
        guard width > 0 else { return 0.0 }
        let ratio = Double(dragOffset / width)
        // Rotate from 0° to ±60° as it moves away from center
        return ratio * 60.0
    }
    
    private func calculateCurrentScale(dragOffset: CGFloat, width: CGFloat) -> Double {
        guard width > 0 else { return 1.0 }
        let normalizedDrag = Double(abs(dragOffset) / width)
        // Scale from 1.0 down to 0.7 as it moves away
        return max(0.7, 1.0 - normalizedDrag * 0.3)
    }
    
    private func calculateCurrentPeriodOpacity(dragOffset: CGFloat, width: CGFloat) -> Double {
        guard width > 0 else { return 1.0 }
        let normalizedDrag = Double(abs(dragOffset) / width)
        // Fade from 1.0 to 0 as it moves away from center
        return max(0.0, 1.0 - normalizedDrag * 3.0)
    }
    
    // MARK: - Next Period Calculations
    
    private func calculateNextRotation(dragOffset: CGFloat, width: CGFloat) -> Double {
        guard width > 0 else { return 60.0 }
        let ratio = Double(dragOffset / width)
        // Rotate from 60° (hidden right) to 0° (center)
        return 60.0 + (ratio * 60.0)
    }
    
    private func calculateNextScale(dragOffset: CGFloat, width: CGFloat) -> Double {
        guard width > 0 else { return 0.7 }
        let ratio = Double(abs(dragOffset) / width)
        // Scale from 0.7 to 1.0 as it approaches center
        return 0.7 + (ratio * 0.3)
    }
    
    private func calculateNextOffset(dragOffset: CGFloat, width: CGFloat) -> CGFloat {
        guard width > 0 else { return 0 }
        let ratio = abs(dragOffset) / width
        // Move from right (width/3) toward center (0)
        return (width / 3) * (1 - ratio)
    }
    
    private func calculateNextPeriodOpacity(dragOffset: CGFloat, width: CGFloat) -> Double {
        guard width > 0 else { return 0.0 }
        if dragOffset < 0 {
            let ratio = Double(abs(dragOffset) / width)
            // Fade in from 0 to 1 as it approaches center
            return min(1.0, ratio * 3.0)
        }
        return 0.0
    }
    
    private var swipeableContentArea: some View {
        GeometryReader { geometry in
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    // Period Description - now part of swipeable content
                    periodDescriptionView
                        .padding(.horizontal, 24)
                        .padding(.bottom, 10)
                    
                    // Main Content
                    VStack(alignment: .leading, spacing: 28) {
                        totalSpendView
                        cardsGrid
                        spendingTrendChart
                        categoryDistributionChart
                        Spacer(minLength: 100)
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 10)
                    .opacity(contentOpacity)
                }
                .offset(x: dragOffset) // Apply drag offset to entire content
            }
            .contentShape(Rectangle()) // Ensure the whole area is swipeable
            .gesture(
                DragGesture()
                    .onChanged { value in
                        // Clamp drag offset to prevent excessive dragging
                        let maxDrag = geometry.size.width * 0.3
                        dragOffset = max(-maxDrag, min(maxDrag, value.translation.width))
                        
                        // Calculate content opacity based on drag distance
                        // Use a safe width to avoid division by zero
                        let safeWidth = max(1.0, geometry.size.width)
                        let dragRatio = abs(value.translation.width) / safeWidth
                        contentOpacity = max(0.3, 1.0 - dragRatio * 2)
                    }
                    .onEnded { value in
                        let threshold: CGFloat = 50
                        if value.translation.width > threshold {
                            // Swipe Right -> Previous Period
                            withAnimation(.easeOut(duration: 0.25)) {
                                contentOpacity = 0
                            }
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                viewModel.movePeriod(by: -1)
                            }
                            // Fade back in
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                                withAnimation(.easeIn(duration: 0.25)) {
                                    contentOpacity = 1.0
                                }
                            }
                        } else if value.translation.width < -threshold {
                            // Swipe Left -> Next Period
                            withAnimation(.easeOut(duration: 0.25)) {
                                contentOpacity = 0
                            }
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                viewModel.movePeriod(by: 1)
                            }
                            // Fade back in
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                                withAnimation(.easeIn(duration: 0.25)) {
                                    contentOpacity = 1.0
                                }
                            }
                        } else {
                            // Didn't meet threshold, restore opacity
                            withAnimation(.easeInOut(duration: 0.2)) {
                                contentOpacity = 1.0
                            }
                        }
                        
                        // Animate drag offset back to 0
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            dragOffset = 0
                        }
                    }
            )
        }
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
    }

    private var cardsGrid: some View {
        HStack(spacing: 16) {
            // Top Category Card
            Button(action: {
                if let category = viewModel.topCategoryNameOnly,
                   let dateRange = viewModel.currentDateRange {
                    historyFilter = HistoryFilter(
                        category: category,
                        dateRange: dateRange,
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
            }
            .buttonStyle(PlainButtonStyle())
            .disabled(viewModel.topCategoryNameOnly == nil)
            
            // Biggest Purchase Card
            if let receiptId = viewModel.biggestPurchaseReceiptId,
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
        }
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
                       let selectedItem = viewModel.categorySpending.first(where: { $0.category == selectedCategory }) {
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
                            Chart(viewModel.spendingTrend, id: \.date) { item in
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
                            .frame(width: max(geometry.size.width, CGFloat(viewModel.spendingTrend.count) * 60))
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
