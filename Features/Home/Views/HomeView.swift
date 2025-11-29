import SwiftUI

struct HomeView: View {
    @ObservedObject var viewModel: HomeViewModel

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            background

            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    header
                    periodSelector
                    kpiCards
                    Spacer(minLength: 40)
                }
                .padding(.horizontal, 20)
                .padding(.top, 32)
            }

            captureButton
                .padding(.trailing, 24)
                .padding(.bottom, 32)
        }
        .onAppear {
            viewModel.onAppear()
        }
    }

    private var background: some View {
        Color(.systemGray6)
            .ignoresSafeArea()
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(greeting())
                .font(.title2.weight(.semibold))

            Text("Here’s how you’re spending this month.")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var periodSelector: some View {
        HStack(spacing: 8) {
            Text(viewModel.periodTitle)
                .font(.subheadline.weight(.medium))

            Spacer()

            Button(action: {
                viewModel.refresh()
            }) {
                Image(systemName: "arrow.clockwise")
                    .font(.subheadline.weight(.semibold))
            }
            .accessibilityLabel("Refresh overview")
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(.ultraThinMaterial, in: Capsule())
        .shadow(color: Color.black.opacity(0.08), radius: 16, x: 0, y: 8)
    }

    private var kpiCards: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 16) {
                HomeKPICardView(
                    title: "Total Spend",
                    value: viewModel.totalSpendText,
                    subtitle: "This period"
                )

                HomeKPICardView(
                    title: "Avg Daily Spend",
                    value: viewModel.averageDailySpendText,
                    subtitle: "Per day"
                )

                HomeKPICardView(
                    title: "Top Merchant",
                    value: viewModel.topMerchantTitle,
                    subtitle: "Highest spend"
                )

                HomeKPICardView(
                    title: "Top Category",
                    value: viewModel.topCategoryTitle,
                    subtitle: "Highest spend"
                )
            }
            .padding(.vertical, 4)
        }
    }

    private var captureButton: some View {
        Button(action: {
            // TODO: Wire into capture flow when available.
        }) {
            ZStack {
                Circle()
                    .fill(.ultraThinMaterial)
                    .frame(width: 64, height: 64)
                    .shadow(color: Color.black.opacity(0.18), radius: 18, x: 0, y: 10)

                Image(systemName: "plus")
                    .font(.title2.weight(.bold))
                    .foregroundColor(Color(.label))
            }
        }
        .accessibilityLabel("Capture expense")
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

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.caption.weight(.medium))
                .foregroundColor(.secondary)

            Text(value)
                .font(.title3.weight(.semibold))

            Text(subtitle)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(16)
        .frame(width: 200, alignment: .leading)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .shadow(color: Color.black.opacity(0.1), radius: 20, x: 0, y: 12)
    }
}


