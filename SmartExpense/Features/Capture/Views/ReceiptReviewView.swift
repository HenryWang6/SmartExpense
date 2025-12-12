//
//  ReceiptReviewView.swift
//  SmartExpense
//
//  Created by Henry Wang on 2025-11-29.
//

import SwiftUI
import CoreData

struct ReceiptReviewView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: ReceiptReviewViewModel
    @Environment(\.managedObjectContext) private var viewContext
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \ExpenseCategory.sortOrder, ascending: true)],
        animation: .default)
    private var categories: FetchedResults<ExpenseCategory>
    
    @State private var isSaving = false
    @State private var showCreateCategorySheet = false
    
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
                        
                        // Conditional content based on capture method
                        if viewModel.captureMethod == "camera", let image = viewModel.receiptImage {
                            scannedPhotoCard(image: image)
                        }
                        
                        if viewModel.captureMethod == "voice" && !viewModel.voiceTranscript.isEmpty {
                            transcriptCard
                        }
                        
//                        // Items section
//                        itemsSection
//                        
//                        // Add item button
//                        addItemButton
//                        
//                        // Calculated total
//                        if !viewModel.items.isEmpty {
//                            calculatedTotalCard
//                        }
                        
                        Spacer(minLength: 100)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                }
            }
            .navigationTitle("Review")
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
                
                if categories.isEmpty {
                    TextField("Merchant category", text: $viewModel.merchantCategory)
                        .font(.system(size: 16, weight: .medium))
                        .padding(14)
                        .background(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(Color(.systemGray6))
                        )
                } else {
                    categorySelectionGrid
                        .padding(8)
                        .background(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(Color(.systemGray6).opacity(0.5)) // Slightly different background for grid
                        )
                }
            }
            
            // Date
            VStack(alignment: .leading, spacing: 8) {
                Text("Date")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.secondary)
                    .textCase(.uppercase)
                    .tracking(0.5)
                
                HStack {
                    DatePicker("", selection: $viewModel.date, displayedComponents: [.date, .hourAndMinute])
                        .labelsHidden()
                    Spacer()
                }
                .padding(14)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Color(.systemGray6))
                )
            }
            
            // Total amount
            VStack(alignment: .leading, spacing: 8) {
                Text("Total Amount")
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
    
    // MARK: - Category Selection Grid
    
    private var categorySelectionGrid: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 80))], spacing: 12) {
            ForEach(categories) { category in
                Button {
                    // Update main Merchant Category field
                    viewModel.merchantCategory = category.name ?? ""
                    
                    // Also update the icon/color if the ViewModel supports it or if we are displaying a live preview
                    // For now, this just updates the text field binding which is what the ViewModel uses.
                } label: {
                    VStack(spacing: 8) {
                        ZStack {
                            Circle()
                                .fill(Color(hex: category.colorHex ?? "#999999"))
                                .frame(width: 44, height: 44)
                            
                            if category.iconType == "sfSymbol" {
                                Image(systemName: category.iconValue ?? "questionmark")
                                    .font(.system(size: 20))
                                    .foregroundColor(.white)
                            } else {
                                Text(category.iconValue ?? "?")
                                    .font(.system(size: 20))
                            }
                            
                            if viewModel.merchantCategory == category.name {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 20))
                                    .foregroundColor(.white)
                                    .background(Circle().fill(Color.blue))
                                    .offset(x: 18, y: -18)
                            }
                        }
                        
                        Text(category.name ?? "Unknown")
                            .font(.caption)
                            .foregroundColor(viewModel.merchantCategory == category.name ? .primary : .secondary)
                            .lineLimit(1)
                    }
                    .padding(8)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(viewModel.merchantCategory == category.name ? Color.blue : Color.clear, lineWidth: 2)
                    )
                }
                .buttonStyle(.plain)
            }
            
            // Add Category Button
            Button {
                showCreateCategorySheet = true
            } label: {
                VStack(spacing: 8) {
                    ZStack {
                        Circle()
                            .fill(Color(.systemGray5))
                            .frame(width: 44, height: 44)
                        
                        Image(systemName: "plus")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.blue)
                    }
                    
                    Text("Add New")
                        .font(.caption)
                        .foregroundColor(.blue)
                        .lineLimit(1)
                }
                .padding(8)
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 8)
        .sheet(isPresented: $showCreateCategorySheet) {
            CategoryCreationSheet(parentContext: viewContext) { newCategory in
                // Select the new category
                if let name = newCategory.name {
                    viewModel.merchantCategory = name
                }
            }
        }
    }
    
    // MARK: - Conditional Content Views
    
    private func scannedPhotoCard(image: UIImage) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "camera.fill")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.blue)
                
                Text("Scanned Receipt")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.secondary)
                    .textCase(.uppercase)
                    .tracking(0.5)
            }
            
            Image(uiImage: image)
                .resizable()
                .scaledToFit()
                .frame(maxWidth: .infinity)
                .cornerRadius(12)
                .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(.ultraThinMaterial)
                .shadow(color: Color.black.opacity(0.06), radius: 16, x: 0, y: 8)
        )
    }
    
    private var transcriptCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "quote.bubble.fill")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.orange)
                
                Text("What you said")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.secondary)
                    .textCase(.uppercase)
                    .tracking(0.5)
            }
            
            Text(viewModel.voiceTranscript)
                .font(.system(size: 16, weight: .regular))
                .foregroundColor(.primary)
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Color(.systemGray6))
                )
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(.ultraThinMaterial)
                .shadow(color: Color.black.opacity(0.06), radius: 16, x: 0, y: 8)
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
    
    return ReceiptReviewView(
        viewModel: ReceiptReviewViewModel(
            extractedData: extractedData,
            image: nil,
            viewContext: context
        )
    )
}
