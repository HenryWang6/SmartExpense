import SwiftUI

struct SettingsView: View {
    var body: some View {
        NavigationStack {
            List {
                Section("Data Management") {
                    NavigationLink(destination: CategoryManagerView()) {
                        Label("Category Management", systemImage: "list.bullet")
                    }
                }
            }
            .navigationTitle("Settings")
        }
    }
}

#Preview {
    SettingsView()
}
