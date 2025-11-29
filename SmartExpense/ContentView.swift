//
//  ContentView.swift
//  SmartExpense
//
//  Created by Henry Wang on 2025-11-29.
//

import SwiftUI
import CoreData

struct ContentView: View {
    @Environment(\.managedObjectContext) private var viewContext

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Receipt.date, ascending: false)],
        animation: .default)
    private var receipts: FetchedResults<Receipt>

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
                        ForEach(receipts) { receipt in
                            NavigationLink {
                                expenseDetailView(receipt: receipt)
                            } label: {
                                ExpenseRowView(receipt: receipt)
                            }
                            .listRowInsets(EdgeInsets(top: 6, leading: 20, bottom: 6, trailing: 20))
                            .listRowBackground(
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .fill(.ultraThinMaterial)
                            )
                        }
                        .onDelete(perform: deleteReceipts)
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
                    Button(action: addReceipt) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.accentColor)
                    }
                }
            }
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
    
    private func expenseDetailView(receipt: Receipt) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Merchant
                VStack(alignment: .leading, spacing: 8) {
                    Text("Merchant")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.secondary)
                        .textCase(.uppercase)
                        .tracking(0.5)
                    
                    Text(receipt.merchantName ?? "Unknown Merchant")
                        .font(.system(size: 20, weight: .semibold))
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(.ultraThinMaterial)
                )
                
                // Date & Time
                VStack(alignment: .leading, spacing: 8) {
                    Text("Date & Time")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.secondary)
                        .textCase(.uppercase)
                        .tracking(0.5)
                    
                    Text(receipt.date ?? Date(), formatter: dateFormatter)
                        .font(.system(size: 20, weight: .semibold))
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(.ultraThinMaterial)
                )
                
                // Total Amount
                VStack(alignment: .leading, spacing: 8) {
                    Text("Total Amount")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.secondary)
                        .textCase(.uppercase)
                        .tracking(0.5)
                    
                    Text("$\(receipt.totalAmount, specifier: "%.2f")")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.accentColor)
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(.ultraThinMaterial)
                )
            }
            .padding()
        }
        .navigationTitle("Expense Details")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func addReceipt() {
        withAnimation {
            let newReceipt = Receipt(context: viewContext)
            newReceipt.id = UUID()
            newReceipt.merchantName = "Sample Merchant"
            newReceipt.date = Date()
            newReceipt.totalAmount = Double.random(in: 10...100)
            newReceipt.isVoiceInput = false
            newReceipt.createdAt = Date()

            do {
                try viewContext.save()
            } catch {
                let nsError = error as NSError
                fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
            }
        }
    }

    private func deleteReceipts(offsets: IndexSet) {
        withAnimation {
            offsets.map { receipts[$0] }.forEach(viewContext.delete)

            do {
                try viewContext.save()
            } catch {
                let nsError = error as NSError
                fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
            }
        }
    }
}

private let dateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .medium
    formatter.timeStyle = .short
    return formatter
}()

struct ExpenseRowView: View {
    let receipt: Receipt
    
    var body: some View {
        HStack(spacing: 16) {
            // Icon
            ZStack {
                Circle()
                    .fill(Color.accentColor.opacity(0.15))
                    .frame(width: 44, height: 44)
                
                Image(systemName: receipt.isVoiceInput ? "mic.fill" : "receipt")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.accentColor)
            }
            
            // Content
            VStack(alignment: .leading, spacing: 4) {
                Text(receipt.merchantName ?? "Unknown Merchant")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.primary)
                
                Text(receipt.date ?? Date(), formatter: dateFormatter)
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Text("$\(receipt.totalAmount, specifier: "%.2f")")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.accentColor)
            
            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.secondary.opacity(0.5))
        }
        .padding(.vertical, 8)
    }
}

#Preview {
    ContentView().environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
