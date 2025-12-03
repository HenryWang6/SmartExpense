//
//  ReceiptEditView.swift
//  SmartExpense
//
//  Created by Henry Wang on 2025-11-29.
//

import SwiftUI
import CoreData

struct ReceiptEditView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: ReceiptEditViewModel
    
    @State private var isSaving = false
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background
                LinearGradient(
                    colors: [
                        Color(.systemBackground),
                        Color(.systemGray6).opacity(0.3)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Header card
                        headerCard
                        
                        // Items section
                        itemsSection
                        
                        // Add item button
                        addItemButton
                        
                        // Calculated total
                        if !viewModel.items.isEmpty {
                            calculatedTotalCard
                        }
                        
                        Spacer(minLength: 100)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                }
            }
            .navigationTitle("Edit Receipt")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.secondary)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: saveReceipt) {
                        if isSaving {
                            ProgressView()
                        } else {
                            Text("Save")
                                .fontWeight(.semibold)
                        }
                    }
                    .disabled(isSaving)
                }
            }
            .alert("Error", isPresented: $viewModel.showingError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(viewModel.errorMessage)
            }
        }
    }
    
    private var headerCard: some View {
        VStack(spacing: 16) {
            Text("Receipt Details")
                .font(.system(size: 18, weight: .bold))
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.bottom, 4)
            
            // Merchant name
            VStack(alignment: .leading, spacing: 8) {
                Text("Merchant")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.secondary)
                    .textCase(.uppercase)
                    .tracking(0.5)
                
                TextField("Merchant name", text: $viewModel.merchantName)
                    .font(.system(size: 18, weight: .semibold))
                    .padding(14)
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(Color(.systemGray6))
                    )
            }
            
            // Merchant Category
            VStack(alignment: .leading, spacing: 8) {
                Text("Category")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.secondary)
                    .textCase(.uppercase)
                    .tracking(0.5)
                
                TextField("Merchant category", text: $viewModel.merchantCategory)
                    .font(.system(size: 16, weight: .medium))
                    .padding(14)
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(Color(.systemGray6))
                    )
            }
            
            HStack(spacing: 12) {
                // Date
                VStack(alignment: .leading, spacing: 8) {
                    Text("Date")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.secondary)
                        .textCase(.uppercase)
                        .tracking(0.5)
                    
                    DatePicker("", selection: $viewModel.date, displayedComponents: [.date, .hourAndMinute])
                        .labelsHidden()
                        .padding(10)
                        .background(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(Color(.systemGray6))
                        )
                }
                .frame(maxWidth: .infinity)
                
                // Total amount
                VStack(alignment: .leading, spacing: 8) {
                    Text("Total")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.secondary)
                        .textCase(.uppercase)
                        .tracking(0.5)
                    
                    HStack {
                        Text("$")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.secondary)
                        
                        TextField("0.00", text: $viewModel.totalAmount)
                            .font(.system(size: 18, weight: .bold))
                            .keyboardType(.decimalPad)
                    }
                    .padding(14)
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(Color(.systemGray6))
                    )
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(.ultraThinMaterial)
                .shadow(color: Color.black.opacity(0.06), radius: 16, x: 0, y: 8)
        )
    }
    
    private var itemsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Line Items")
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundColor(.primary)
                .padding(.horizontal, 4)
            
            ForEach(Array(viewModel.items.enumerated()), id: \.element.id) { index, _ in
                LineItemRowView(
                    item: $viewModel.items[index],
                    onDelete: {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            viewModel.removeItem(at: index)
                        }
                    }
                )
            }
        }
    }
    
    private var addItemButton: some View {
        Button(action: {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                viewModel.addItem()
            }
        }) {
            HStack(spacing: 8) {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 18, weight: .semibold))
                Text("Add Item")
                    .font(.system(size: 16, weight: .semibold))
            }
            .foregroundColor(.green)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(Color.green.opacity(0.3), style: StrokeStyle(lineWidth: 2, dash: [8, 4]))
                    )
            )
        }
    }
    
    private var calculatedTotalCard: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Items Total")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.secondary)
                    .textCase(.uppercase)
                    .tracking(0.5)
                
                Text(viewModel.calculatedTotalText)
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
            }
            
            Spacer()
            
            Image(systemName: "info.circle")
                .font(.system(size: 20))
                .foregroundColor(.secondary)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(Color.green.opacity(0.2), lineWidth: 1)
                )
        )
    }
    
    private func saveReceipt() {
        isSaving = true
        
        Task {
            let success = await viewModel.save()
            
            await MainActor.run {
                isSaving = false
                if success {
                    dismiss()
                }
            }
        }
    }
}

#Preview {
    let context = PersistenceController.preview.container.viewContext
    let extractedData = ExtractedReceiptData(
        merchantName: "Starbucks",
        date: Date(),
        totalAmount: 23.50,
        items: [
            ExtractedLineItem(description: "Coffee", quantity: 2, unitPrice: 4.50, subtotal: 9.00),
            ExtractedLineItem(description: "Pastry", quantity: 1, unitPrice: 5.50, subtotal: 5.50)
        ],
        confidence: .high
    )
    
    return ReceiptEditView(
        viewModel: ReceiptEditViewModel(
            extractedData: extractedData,
            image: nil,
            viewContext: context
        )
    )
}
