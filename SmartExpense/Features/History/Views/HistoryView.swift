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
    
    @State private var selectedCaptureOption: CaptureOption?
    @State private var expandedSections: Set<String> = []
    
    let filter: HistoryFilter?
    
    // Initializer to set default expanded sections and optional filter
    init(filter: HistoryFilter? = nil) {
        self.filter = filter
        _expandedSections = State(initialValue: Set(["Today", "This Week"]))
        
        // Build predicate based on filter
        var predicates: [NSPredicate] = []
        
        if let category = filter?.category {
            predicates.append(NSPredicate(format: "merchantCategory == %@", category))
        }
        
        if let dateRange = filter?.dateRange {
            predicates.append(NSPredicate(format: "date >= %@ AND date <= %@", dateRange.start as NSDate, dateRange.end as NSDate))
        }
        
        let finalPredicate = predicates.isEmpty ? nil : NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
        
        _receipts = FetchRequest(
            sortDescriptors: [NSSortDescriptor(keyPath: \Receipt.date, ascending: false)],
            predicate: finalPredicate,
            animation: .default
        )
    }


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
                    VStack(spacing: 0) {
                        // Filter Banner
                        if let filter = filter {
                            filterBanner(filter: filter)
                                .padding(.horizontal, 16)
                                .padding(.top, 8)
                        }
                        
                        List {
                            ForEach(groupedReceipts, id: \.section) { group in
                                DisclosureGroup(
                                    isExpanded: Binding(
                                        get: { expandedSections.contains(group.section) },
                                        set: { isExpanded in
                                            if isExpanded {
                                                expandedSections.insert(group.section)
                                            } else {
                                                expandedSections.remove(group.section)
                                            }
                                        }
                                    )
                                ) {
                                    ForEach(group.receipts) { receipt in
                                        NavigationLink {
                                            ExpenseDetailView(receipt: receipt, onDateChanged: { newDate in
                                                let newSection = sectionName(for: newDate)
                                                withAnimation {
                                                    expandedSections.insert(newSection)
                                                }
                                            })
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
                                } label: {
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
            }
            .navigationTitle("Expenses")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                if filter == nil {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        if !receipts.isEmpty {
                            EditButton()
                                .foregroundColor(.accentColor)
                        }
                    }
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Menu {
                            // Manual Entry
                            Button(action: {
                                selectedCaptureOption = .manual
                            }) {
                                Label(CaptureOption.manual.title, systemImage: CaptureOption.manual.icon)
                            }
                            
                            // Voice Input
                            Button(action: {
                                selectedCaptureOption = .voice
                            }) {
                                Label(CaptureOption.voice.title, systemImage: CaptureOption.voice.icon)
                            }
                            
                            // Scan (Camera)
                            Button(action: {
                                selectedCaptureOption = .camera
                            }) {
                                Label(CaptureOption.camera.title, systemImage: CaptureOption.camera.icon)
                            }
                        } label: {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundColor(.accentColor)
                        }
                    }
                }
            }
            .fullScreenCover(item: $selectedCaptureOption) { option in
                CaptureCoordinatorView(initialMode: option)
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .NSManagedObjectContextDidSave)) { _ in
            viewContext.refreshAllObjects()
        }
    }
    
    private var groupedReceipts: [ReceiptGroup] {
        let calendar = Calendar.current
        let now = Date()
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMMM"
        
        var groups: [String: [Receipt]] = [:]
        
        // Calculate sections
        let currentMonthName = dateFormatter.string(from: now)
        
        var previousMonths: [String] = []
        for i in 1...3 {
            if let date = calendar.date(byAdding: .month, value: -i, to: now) {
                previousMonths.append(dateFormatter.string(from: date))
            }
        }
        
        for receipt in receipts {
            let section = sectionName(for: receipt.date ?? Date())
             
            if groups[section] == nil {
                groups[section] = []
            }
            groups[section]?.append(receipt)
        }
         
        var sectionOrder = ["Today", "This Week", currentMonthName]
        sectionOrder.append(contentsOf: previousMonths)
        sectionOrder.append("Earlier")
         
        return sectionOrder.compactMap { sectionName in
            guard let receipts = groups[sectionName], !receipts.isEmpty else { return nil }
            return ReceiptGroup(section: sectionName, receipts: receipts)
        }
    }
    
    private func sectionName(for date: Date) -> String {
        let calendar = Calendar.current
        let now = Date()
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMMM"
        
        if calendar.isDateInToday(date) {
            return "Today"
        } else if calendar.isDate(date, equalTo: now, toGranularity: .weekOfYear) {
            return "This Week"
        } else if calendar.isDate(date, equalTo: now, toGranularity: .month) {
            return dateFormatter.string(from: now)
        } else {
            // Check previous 3 months
            for i in 1...3 {
                if let prevDate = calendar.date(byAdding: .month, value: -i, to: now),
                   calendar.isDate(date, equalTo: prevDate, toGranularity: .month) {
                    return dateFormatter.string(from: prevDate)
                }
            }
            return "Earlier"
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
    
    private func filterBanner(filter: HistoryFilter) -> some View {
        HStack {
            Image(systemName: "line.3.horizontal.decrease.circle.fill")
                .foregroundColor(.accentColor)
            
            Text("Showing: \(filter.displayText)")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.primary)
            
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.accentColor.opacity(0.1))
        )
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



#Preview {
    HistoryView().environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
