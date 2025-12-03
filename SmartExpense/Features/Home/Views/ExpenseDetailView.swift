//
//  ExpenseDetailView.swift
//  SmartExpense
//
//  Created by Henry Wang on 2025-12-03.
//

import SwiftUI
import CoreData

struct ExpenseDetailView: View {
    let receipt: Receipt
    
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
                    
                    // Merchant Details
                    merchantSection
                    
                    // Line Items
                    if let items = receipt.items?.allObjects as? [ReceiptItem], !items.isEmpty {
                        lineItemsSection(items: items.sorted(by: { $0.sortOrder < $1.sortOrder }))
                    }
                    
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
                    .padding(16)
                }
            }
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color(.systemBackground))
                    .shadow(color: Color.black.opacity(0.03), radius: 8, x: 0, y: 2)
            )
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
