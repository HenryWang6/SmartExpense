//
//  LineItemRowView.swift
//  SmartExpense
//
//  Created by Henry Wang on 2025-11-29.
//

import SwiftUI

struct LineItemRowView: View {
    @Binding var item: EditableLineItem
    let onDelete: () -> Void
    
    @FocusState private var focusedField: Field?
    
    enum Field {
        case description, category, quantity, unitPrice, subtotal
    }
    
    var body: some View {
        VStack(spacing: 12) {
            // Description
            VStack(alignment: .leading, spacing: 6) {
                Text("Description")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.secondary)
                    .textCase(.uppercase)
                    .tracking(0.5)
                
                TextField("Item description", text: $item.description)
                    .font(.system(size: 16, weight: .regular))
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(Color(.systemGray6))
                    )
                    .focused($focusedField, equals: .description)
            }
            
            // Category
            VStack(alignment: .leading, spacing: 6) {
                Text("Category")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.secondary)
                    .textCase(.uppercase)
                    .tracking(0.5)
                
                TextField("Item category", text: $item.category)
                    .font(.system(size: 16, weight: .regular))
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(Color(.systemGray6))
                    )
                    .focused($focusedField, equals: .category)
            }
            
            // Quantity, Unit Price, Subtotal
            HStack(spacing: 12) {
                // Quantity
                VStack(alignment: .leading, spacing: 6) {
                    Text("Qty")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.secondary)
                        .textCase(.uppercase)
                        .tracking(0.5)
                    
                    TextField("1", value: $item.quantity, format: .number)
                        .font(.system(size: 16, weight: .regular))
                        .keyboardType(.decimalPad)
                        .padding(12)
                        .background(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .fill(Color(.systemGray6))
                        )
                        .focused($focusedField, equals: .quantity)
                }
                .frame(maxWidth: .infinity)
                
                // Unit Price
                VStack(alignment: .leading, spacing: 6) {
                    Text("Price")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.secondary)
                        .textCase(.uppercase)
                        .tracking(0.5)
                    
                    TextField("0.00", value: $item.unitPrice, format: .currency(code: "USD"))
                        .font(.system(size: 16, weight: .regular))
                        .keyboardType(.decimalPad)
                        .padding(12)
                        .background(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .fill(Color(.systemGray6))
                        )
                        .focused($focusedField, equals: .unitPrice)
                        .onChange(of: item.unitPrice) { _, newValue in
                            updateSubtotal()
                        }
                        .onChange(of: item.quantity) { _, newValue in
                            updateSubtotal()
                        }
                }
                .frame(maxWidth: .infinity)
                
                // Subtotal
                VStack(alignment: .leading, spacing: 6) {
                    Text("Total")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.secondary)
                        .textCase(.uppercase)
                        .tracking(0.5)
                    
                    TextField("0.00", value: $item.subtotal, format: .currency(code: "USD"))
                        .font(.system(size: 16, weight: .semibold))
                        .keyboardType(.decimalPad)
                        .padding(12)
                        .background(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .fill(Color(.systemGray6))
                        )
                        .focused($focusedField, equals: .subtotal)
                }
                .frame(maxWidth: .infinity)
            }
            
            // Delete button
            Button(action: onDelete) {
                HStack {
                    Image(systemName: "trash")
                        .font(.system(size: 14, weight: .semibold))
                    Text("Remove Item")
                        .font(.system(size: 14, weight: .semibold))
                }
                .foregroundColor(.red)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(Color.red.opacity(0.1))
                )
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(Color(.systemGray4).opacity(0.3), lineWidth: 1)
                )
        )
    }
    
    private func updateSubtotal() {
        item.subtotal = item.quantity * item.unitPrice
    }
}

#Preview {
    @Previewable @State var item = EditableLineItem(
        description: "Coffee",
        category: "Food & Drink",
        quantity: 2,
        unitPrice: 4.50,
        subtotal: 9.00
    )
    
    return LineItemRowView(item: $item) {
        print("Delete")
    }
    .padding()
}
