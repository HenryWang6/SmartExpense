import SwiftUI

struct HomeView: View {
    @ObservedObject var viewModel: HomeViewModel

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            background

            ScrollView {
                VStack(alignment: .leading, spacing: 28) {
                    header
                    periodSelector
                    kpiCards
                    Spacer(minLength: 100)
                }
                .padding(.horizontal, 24)
                .padding(.top, 20)
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

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(greeting())
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.primary, .primary.opacity(0.8)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )

            Text("Here's how you're spending this month.")
                .font(.system(size: 16, weight: .regular))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, 8)
    }

    private var periodSelector: some View {
        HStack(spacing: 12) {
            Image(systemName: "calendar")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.secondary)
            
            Text(viewModel.periodTitle)
                .font(.system(size: 15, weight: .semibold))

            Spacer()

            Button(action: {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    viewModel.refresh()
                }
            }) {
                Image(systemName: "arrow.clockwise")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.primary)
                    .rotationEffect(.degrees(viewModel.state == .loading ? 360 : 0))
                    .animation(
                        viewModel.state == .loading
                            ? .linear(duration: 1).repeatForever(autoreverses: false)
                            : .default,
                        value: viewModel.state == .loading
                    )
            }
            .accessibilityLabel("Refresh overview")
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(.ultraThinMaterial)
                .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 4)
        )
    }

    private var kpiCards: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 16) {
                HomeKPICardView(
                    title: "Total Spend",
                    value: viewModel.totalSpendText,
                    subtitle: "This period",
                    icon: "dollarsign.circle.fill",
                    color: .blue
                )

                HomeKPICardView(
                    title: "Avg Daily Spend",
                    value: viewModel.averageDailySpendText,
                    subtitle: "Per day",
                    icon: "chart.line.uptrend.xyaxis",
                    color: .green
                )

                HomeKPICardView(
                    title: "Top Merchant",
                    value: viewModel.topMerchantTitle,
                    subtitle: "Highest spend",
                    icon: "storefront.fill",
                    color: .orange
                )

                HomeKPICardView(
                    title: "Top Category",
                    value: viewModel.topCategoryTitle,
                    subtitle: "Highest spend",
                    icon: "tag.fill",
                    color: .purple
                )
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 4)
        }
    }

    private var captureButton: some View {
        Button(action: {
            // TODO: Wire into capture flow when available.
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
    }

    private func greeting(date: Date = Date()) -> String {
        let hour = Calendar.current.component(.hour, from: date)
        switch hour {
        case 5..<12:
            return "Good morning"
        case 12..<17:
            return "Good afternoon"
        default:
            return "Good evening"
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


