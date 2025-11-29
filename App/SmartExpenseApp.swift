import SwiftUI

@main
struct SmartExpenseApp: App {
    var body: some Scene {
        WindowGroup {
            RootTabView()
        }
    }
}

struct RootTabView: View {
    var body: some View {
        TabView {
            HomeView(viewModel: HomeViewModel(service: HomeOverviewMockService()))
                .tabItem {
                    Image(systemName: "house.fill")
                    Text("Home")
                }

            // Placeholder for History tab (receipts & expenses list)
            Text("History")
                .tabItem {
                    Image(systemName: "clock")
                    Text("History")
                }

            // Placeholder for Profile / Settings tab
            Text("Settings")
                .tabItem {
                    Image(systemName: "gearshape")
                    Text("Settings")
                }
        }
    }
}


