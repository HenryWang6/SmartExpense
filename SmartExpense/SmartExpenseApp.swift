//
//  SmartExpenseApp.swift
//  SmartExpense
//
//  Created by Henry Wang on 2025-11-29.
//

import SwiftUI
import CoreData

@main
struct SmartExpenseApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            RootTabView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
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
            ContentView()
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
        .tint(.accentColor)
    }
}

#Preview {
    RootTabView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
