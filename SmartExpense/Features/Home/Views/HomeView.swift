import SwiftUI
import Charts
import CoreData

struct HomeView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @ObservedObject var viewModel: HomeViewModel
    
    // We need to pass this binding to pages, but managing it at top level is fine
    @State private var historyFilter: HistoryFilter?
    @State private var selectedCaptureOption: CaptureOption?
    @Namespace private var namespace

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottomTrailing) {
                background
                
                VStack(spacing: 0) {
                    // Fixed Header Area - Period Selector
                    PeriodNavigationBar(viewModel: viewModel, namespace: namespace)
                        .padding(.top, 20)
                        .padding(.bottom, 10)
                        .background(.ultraThinMaterial) // Optional: add background for better readability
                    
                    // Swipeable Content Area
                    TabView(selection: Binding(
                        get: { viewModel.currentReferenceDate },
                        set: { viewModel.selectDate($0) }
                    )) {
                        ForEach(viewModel.availableDates, id: \.self) { date in
                            HomeContentPage(date: date, viewModel: viewModel, historyFilter: $historyFilter)
                                .tag(date)
                        }
                    }
                    .tabViewStyle(.page(indexDisplayMode: .never))
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

    private var captureButton: some View {
        Menu {
            // Order: Manual, Voice, Camera (Scan) to match iOS 18 style / User preference
            Button(action: {
                selectedCaptureOption = .manual
            }) {
                Label(CaptureOption.manual.title, systemImage: CaptureOption.manual.icon)
            }
            
            Button(action: {
                selectedCaptureOption = .voice
            }) {
                Label(CaptureOption.voice.title, systemImage: CaptureOption.voice.icon)
            }
            
            Button(action: {
                selectedCaptureOption = .camera
            }) {
                Label(CaptureOption.camera.title, systemImage: CaptureOption.camera.icon)
            }
        } label: {
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
        .fullScreenCover(item: $selectedCaptureOption) { option in
            CaptureCoordinatorView(startOption: option)
        }
    }
    
}

struct PeriodNavigationBar: View {
    @ObservedObject var viewModel: HomeViewModel
    var namespace: Namespace.ID
    
    var body: some View {
        VStack(spacing: 12) {
            // Period Type Selector (Weekly/Monthly/Yearly)
            // Kept from original design but cleaner
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
                                            .matchedGeometryEffect(id: "PeriodTypeCursor", in: namespace)
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
            .padding(.horizontal, 24)

            // Scrollable Date List
            ScrollViewReader { proxy in
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 24) {
                        ForEach(viewModel.availableDates, id: \.self) { date in
                            Button(action: {
                                withAnimation {
                                    viewModel.selectDate(date)
                                }
                            }) {
                                VStack(spacing: 8) {
                                    Text(viewModel.title(for: date))
                                        .font(.system(size: 15, weight: viewModel.title(for: date) == viewModel.title(for: viewModel.currentReferenceDate) ? .bold : .medium))
                                        .foregroundColor(viewModel.title(for: date) == viewModel.title(for: viewModel.currentReferenceDate) ? .primary : .secondary)
                                        .fixedSize() // Prevent truncation
                                    
                                    // Visual Indicator
                                    if viewModel.title(for: date) == viewModel.title(for: viewModel.currentReferenceDate) {
                                        Capsule()
                                            .fill(Color.accentColor)
                                            .frame(height: 3)
                                            .matchedGeometryEffect(id: "ActiveDateIndicator", in: namespace)
                                    } else {
                                        Capsule()
                                            .fill(Color.clear)
                                            .frame(height: 3)
                                    }
                                }
                            }
                            .id(date)
                        }
                    }
                    .padding(.horizontal, 24)
                }
                .onChange(of: viewModel.currentReferenceDate) { _, newDate in
                    withAnimation {
                        proxy.scrollTo(newDate, anchor: .center)
                    }
                }
                .onAppear {
                    // Initial scroll
                    proxy.scrollTo(viewModel.currentReferenceDate, anchor: .center)
                }
            }
        }
    }
}

#Preview {
    HomeView(viewModel: HomeViewModel(service: HomeOverviewMockService()))
}
