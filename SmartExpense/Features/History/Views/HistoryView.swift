//
//  HistoryView.swift
//  SmartExpense
//
//  Created by Henry Wang on 2025-11-29.
//

import SwiftUI
import CoreData

struct HistoryView: View {
    @Environment(\.managedObjectContext) private var viewContext

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Receipt.date, ascending: false)],
        animation: .default)
    private var receipts: FetchedResults<Receipt>
    
    @State private var showingCaptureFlow = false


    var body: some View {
        NavigationView {
            ZStack {
                // Background gradient
                LinearGradient(
                    colors: [
                        Color(.systemBackground),
                        Color(.systemGray6).opacity(0.3)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                if receipts.isEmpty {
                    emptyStateView
                } else {
                    List {
                        ForEach(groupedReceipts, id: \.section) { group in
                            Section {
                                ForEach(group.receipts) { receipt in
                                    NavigationLink {
                                        ExpenseDetailView(receipt: receipt)
                                    } label: {
                                        ExpenseRowView(receipt: receipt)
                                    }
                                    .listRowInsets(EdgeInsets(top: 6, leading: 20, bottom: 6, trailing: 20))
                                    .listRowBackground(
                                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                                            .fill(.ultraThinMaterial)
                                    )
                                }
                                .onDelete { offsets in
                                    deleteReceipts(from: group, at: offsets)
                                }
                            } header: {
                                Text(group.section)
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(.secondary)
                                    .textCase(.uppercase)
                                    .tracking(0.5)
                            }
                        }
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                }
            }
            .navigationTitle("Expenses")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    if !receipts.isEmpty {
                        EditButton()
                            .foregroundColor(.accentColor)
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingCaptureFlow = true }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.accentColor)
                    }
                }
            }
            .fullScreenCover(isPresented: $showingCaptureFlow) {
                CaptureCoordinatorView()
            }
        }
    }
    
    private var groupedReceipts: [ReceiptGroup] {
        let calendar = Calendar.current
        let now = Date()
        
        var groups: [String: [Receipt]] = [:]
        
        for receipt in receipts {
            let receiptDate = receipt.date ?? Date()
            let section: String
            
            if calendar.isDateInToday(receiptDate) {
                section = "Today"
            } else if calendar.isDateInYesterday(receiptDate) {
                section = "Yesterday"
            } else if calendar.isDate(receiptDate, equalTo: now, toGranularity: .weekOfYear) {
                section = "This Week"
            } else if let lastWeekStart = calendar.date(byAdding: .weekOfYear, value: -1, to: now),
                      calendar.isDate(receiptDate, equalTo: lastWeekStart, toGranularity: .weekOfYear) {
                section = "Last Week"
            } else {
                section = "Earlier"
            }
            
            if groups[section] == nil {
                groups[section] = []
            }
            groups[section]?.append(receipt)
        }
        
        let sectionOrder = ["Today", "Yesterday", "This Week", "Last Week", "Earlier"]
        return sectionOrder.compactMap { sectionName in
            guard let receipts = groups[sectionName], !receipts.isEmpty else { return nil }
            return ReceiptGroup(section: sectionName, receipts: receipts)
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "tray")
                .font(.system(size: 60, weight: .light))
                .foregroundColor(.secondary.opacity(0.5))
            
            Text("No Expenses Yet")
                .font(.system(size: 24, weight: .semibold))
                .foregroundColor(.primary)
            
            Text("Tap the + button to add your first expense")
                .font(.system(size: 16, weight: .regular))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
    }
    



    private func deleteReceipts(from group: ReceiptGroup, at offsets: IndexSet) {
        withAnimation {
            offsets.map { group.receipts[$0] }.forEach(viewContext.delete)

            do {
                try viewContext.save()
            } catch {
                let nsError = error as NSError
                fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
            }
        }
    }
}

// For backward compatibility, keep ContentView as a typealias
typealias ContentView = HistoryView

#Preview {
    HistoryView().environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
