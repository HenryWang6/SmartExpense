//
//  ExpenseDetailView.swift
//  SmartExpense
//
//  Created by Henry Wang on 2025-12-03.
//

import SwiftUI
import CoreData

struct ExpenseDetailView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @ObservedObject var receipt: Receipt
    
    var body: some View {
        ZStack {
            // Background
            Color(.systemGray6)
                .opacity(0.3)
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 24) {
                    // Header Card (Total & Date)
                    headerCard
                    
                    // Capture Info
                    captureInfoSection
                    
                    // Merchant Details
                    merchantSection
                    
//                    // Line Items
//                    if let items = receipt.items?.allObjects as? [ReceiptItem], !items.isEmpty {
//                        lineItemsSection(items: items.sorted(by: { $0.sortOrder < $1.sortOrder }))
//                    }
                    
                    // Note Section
                    noteSection
                    
                    // Receipt Image (if available)
                    if let imagePath = receipt.imagePath,
                       let uiImage = FileStorageService.shared.loadReceiptImage(filename: imagePath) {
                        receiptImageSection(image: uiImage)
                    }
                    
                    Spacer(minLength: 40)
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
            }
        }
        .navigationTitle("Expense Details")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private var headerCard: some View {
        VStack(spacing: 8) {
            Text("Total Amount")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.secondary)
                .textCase(.uppercase)
                .tracking(0.5)
            
            Text("$\(receipt.totalAmount, specifier: "%.2f")")
                .font(.system(size: 40, weight: .bold, design: .rounded))
                .foregroundColor(.primary)
            
            Text(receipt.date ?? Date(), formatter: dateFormatter)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.secondary)
                .padding(.top, 4)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(.ultraThinMaterial)
                .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
        )
    }
    
    private var merchantSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Merchant Details")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.primary)
                .padding(.horizontal, 4)
            
            VStack(spacing: 0) {
                detailRow(title: "Merchant", value: receipt.merchantName ?? "Unknown")
                
                Divider()
                    .padding(.leading, 16)
                
                detailRow(title: "Category", value: receipt.merchantCategory?.isEmpty == false ? receipt.merchantCategory! : "Uncategorized")
            }
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color(.systemBackground))
                    .shadow(color: Color.black.opacity(0.03), radius: 8, x: 0, y: 2)
            )
        }
    }
    
    private var captureInfoSection: some View {
        HStack {
            Text("Capture Method")
                .font(.system(size: 16, weight: .regular))
                .foregroundColor(.secondary)
            
            Spacer()
            
            HStack(spacing: 6) {
                Image(systemName: captureMethodIcon)
                    .font(.system(size: 14))
                
                Text(receipt.captureMethod?.capitalized ?? "Manual")
                    .font(.system(size: 16, weight: .semibold))
            }
            .foregroundColor(.primary)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Color(.systemGray6))
            .cornerRadius(8)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.03), radius: 8, x: 0, y: 2)
        )
    }
    
    private var captureMethodIcon: String {
        switch receipt.captureMethod?.lowercased() {
        case "camera", "scan": return "camera.fill"
        case "voice": return "mic.fill"
        default: return "keyboard"
        }
    }
    
    private func detailRow(title: String, value: String) -> some View {
        HStack {
            Text(title)
                .font(.system(size: 16, weight: .regular))
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text(value)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.primary)
        }
        .padding(16)
    }
    
    // Custom Disclosure Group Style to remove default padding/content indentation if needed,
    // but default might be fine. We'll use standard DisclosureGroup for simplicity first.
    
    private func lineItemsSection(items: [ReceiptItem]) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Line Items")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.primary)
                .padding(.horizontal, 4)
            
            VStack(spacing: 0) {
                ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                    if index > 0 {
                        Divider()
                            .padding(.leading, 16)
                    }
                    
                    DisclosureGroup {
                        VStack(spacing: 8) {
                            Divider()
                            
                            HStack {
                                Text("Unit Price")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                Spacer()
                                Text("$\(item.unitPrice, specifier: "%.2f")")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                            }
                            
                            HStack {
                                Text("Quantity")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                Spacer()
                                Text("\(item.quantity, specifier: "%.1f")")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                            }
                            
                            HStack {
                                Text("Subtotal")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                Spacer()
                                Text("$\(item.subtotal, specifier: "%.2f")")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                            }
                        }
                        .padding(.top, 8)
                        .padding(.bottom, 8)
                    } label: {
                        HStack(alignment: .top, spacing: 12) {
                            // Quantity badge
                            Text("\(Int(item.quantity))x")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(.secondary)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color(.systemGray6))
                                .cornerRadius(6)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(item.itemDescription ?? "Item")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.primary)
                                    .multilineTextAlignment(.leading)
                                
                                if let category = item.category, !category.isEmpty {
                                    Text(category)
                                        .font(.system(size: 12, weight: .medium))
                                        .foregroundColor(.secondary)
                                }
                            }
                            
                            Spacer()
                            
                            Text("$\(item.subtotal, specifier: "%.2f")")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.primary)
                        }
                        .padding(.vertical, 12)
                    }
                    .padding(.horizontal, 16)
                    .accentColor(.secondary)
                }
            }
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color(.systemBackground))
                    .shadow(color: Color.black.opacity(0.03), radius: 8, x: 0, y: 2)
            )
        }
    }
    
    private var noteSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Notes")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.primary)
                .padding(.horizontal, 4)
            
            VStack {
                TextEditor(text: Binding(
                    get: { receipt.note ?? "" },
                    set: { 
                        receipt.note = $0 
                        saveContext()
                    }
                ))
                .frame(minHeight: 100)
                .scrollContentBackground(.hidden)
                .background(Color(.systemBackground))
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color(.systemBackground))
                    .shadow(color: Color.black.opacity(0.03), radius: 8, x: 0, y: 2)
            )
        }
    }
    
    private func saveContext() {
        do {
            try viewContext.save()
        } catch {
            print("Error saving note: \(error)")
        }
    }
    
    private func receiptImageSection(image: UIImage) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Receipt Image")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.primary)
                .padding(.horizontal, 4)
            
            Image(uiImage: image)
                .resizable()
                .scaledToFit()
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
        }
    }
}

private let dateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .medium
    formatter.timeStyle = .short
    return formatter
}()
