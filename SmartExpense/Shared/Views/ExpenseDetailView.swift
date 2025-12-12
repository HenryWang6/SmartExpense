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
    var onDateChanged: ((Date) -> Void)?
    
    @State private var isEditing = false
    @State private var editedAmount: Double = 0.0
    @State private var editedMerchant: String = ""
    @State private var editedCategory: String = ""
    @State private var editedDate: Date = Date()
    
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
                    // Receipt Image
                    receiptImageSection
                    
                    Spacer(minLength: 40)
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
            }
        }
        .navigationTitle("Expense Details")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                if isEditing {
                    HStack {
                        Button("Discard") {
                            withAnimation {
                                isEditing = false
                            }
                        }
                        Button("Save") {
                            saveChanges()
                            withAnimation {
                                isEditing = false
                            }
                        }
                        .fontWeight(.bold)
                    }
                } else {
                    Button("Edit") {
                        startEditing()
                        withAnimation {
                            isEditing = true
                        }
                    }
                }
            }
        }
        .fullScreenCover(isPresented: $showScanner) {
            DocumentScannerView { image in
                handleImageCaptured(image)
            }
            .ignoresSafeArea()
        }
        .alert("Camera Not Available", isPresented: $showCameraAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("The camera is not available on this device. Please use a real device to test scanning.")
        }
        .onReceive(NotificationCenter.default.publisher(for: .categoryUpdated)) { _ in
            // Refresh category view if needed, though @FetchRequest handles list.
            // If the category of *this* receipt was renamed, strict property observation on `receipt`
            // should handle it because we updated the `merchantCategory` string in `CategoryInlineRow`.
            // However, forcing a UI refresh or re-checking validity is safe.
        }
    }
    
    private func startEditing() {
        editedAmount = receipt.totalAmount
        editedMerchant = receipt.merchantName ?? ""
        editedCategory = receipt.merchantCategory ?? ""
        editedDate = receipt.date ?? Date()
    }
    
    private func saveChanges() {
        if receipt.date != editedDate {
            onDateChanged?(editedDate)
        }
        
        receipt.totalAmount = editedAmount
        receipt.merchantName = editedMerchant
        receipt.merchantCategory = editedCategory
        receipt.date = editedDate
        
        do {
            try viewContext.save()
            // NotificationCenter.default.post(name: .receiptSaved, object: nil) // Removed: Observers now listen to ContextDidSave
        } catch {
            print("Error saving receipt: \(error)")
        }
    }
    
    // MARK: - Scanner Logic
    @State private var showScanner = false
    @State private var showCameraAlert = false
    
    private func checkCameraPermission() {
        // Check if camera is available (not available on simulator)
        guard UIImagePickerController.isSourceTypeAvailable(.camera) else {
            showCameraAlert = true
            return
        }
        
        Task {
            let status = PermissionsManager.shared.checkCameraPermission()
            
            if status == .authorized {
                await MainActor.run {
                    showScanner = true
                }
            } else if status == .notDetermined {
                let granted = await PermissionsManager.shared.requestCameraPermission()
                if granted {
                    await MainActor.run {
                        showScanner = true
                    }
                }
            } else {
                // Permission denied - strictly speaking we might want to alert user here too,
                // but following pattern from CaptureCoordinatorView usually implies just not showing or handling gracefully.
                // For now we will just do nothing if denied, maybe add alert later if needed.
            }
        }
    }
    
    private func handleImageCaptured(_ image: UIImage) {
        // Save image using FileStorageService
        if let filename = FileStorageService.shared.saveReceiptImage(image) {
            // Update receipt
            receipt.imagePath = filename
            
            do {
                try viewContext.save()
                // NotificationCenter.default.post(name: .receiptSaved, object: nil) // Removed
            } catch {
                print("Error saving receipt image path: \(error)")
            }
        }
        
        showScanner = false
    }
    
    private var headerCard: some View {
        VStack(spacing: 8) {
            Text("Total Amount")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.secondary)
                .textCase(.uppercase)
                .tracking(0.5)
            
            if isEditing {
                TextField("0.00", value: $editedAmount, format: .currency(code: Locale.current.currency?.identifier ?? "USD"))
                    .font(.system(size: 40, weight: .bold, design: .rounded))
                    .multilineTextAlignment(.center)
                    .keyboardType(.decimalPad)
                    .foregroundColor(.primary)
                
                DatePicker("", selection: $editedDate, displayedComponents: [.date, .hourAndMinute])
                    .labelsHidden()
            } else {
                Text(receipt.totalAmount, format: .currency(code: Locale.current.currency?.identifier ?? "USD"))
                    .font(.system(size: 40, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
                
                Text(receipt.date ?? Date(), formatter: dateFormatter)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.secondary)
                    .padding(.top, 4)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(.ultraThinMaterial)
                .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
        )
    }
    
    // MARK: - New Category Selection Logic
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \ExpenseCategory.sortOrder, ascending: true)],
        animation: .default)
    private var categories: FetchedResults<ExpenseCategory>
    
    private var categorySelectionGrid: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 80))], spacing: 12) {
            ForEach(categories) { category in
                Button {
                    editedCategory = category.name ?? ""
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
                            
                            if editedCategory == category.name {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 20))
                                    .foregroundColor(.white)
                                    .background(Circle().fill(Color.blue))
                                    .offset(x: 18, y: -18)
                            }
                        }
                        
                        Text(category.name ?? "Unknown")
                            .font(.caption)
                            .foregroundColor(editedCategory == category.name ? .primary : .secondary)
                            .lineLimit(1)
                    }
                    .padding(8)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(editedCategory == category.name ? Color.blue : Color.clear, lineWidth: 2)
                    )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.vertical, 8)
    }
    
    // MARK: - Modified Merchant Section
    private var merchantSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Merchant Details")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.primary)
                .padding(.horizontal, 4)
            
            if isEditing {
                VStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Merchant")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.secondary)
                        TextField("Merchant Name", text: $editedMerchant)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Category")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.secondary)
                        
                        // NEW: Category Visual Selection
                        if categories.isEmpty {
                            TextField("Category", text: $editedCategory)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                        } else {
                            categorySelectionGrid
                        }
                    }
                }
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(Color(.systemBackground))
                        .shadow(color: Color.black.opacity(0.03), radius: 8, x: 0, y: 2)
                )
            } else {
                VStack(spacing: 0) {
                    detailRow(title: "Merchant", value: receipt.merchantName ?? "Unknown")
                    
                    Divider()
                        .padding(.leading, 16)
                    
                    categoryDisplayRow
                }
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(Color(.systemBackground))
                        .shadow(color: Color.black.opacity(0.03), radius: 8, x: 0, y: 2)
                )
            }
        }
    }
    
    // Helper for read-only category display
    private var categoryDisplayRow: some View {
        HStack {
            Text("Category")
                .font(.system(size: 16, weight: .regular))
                .foregroundColor(.secondary)
            
            Spacer()
            
            if let categoryName = receipt.merchantCategory, !categoryName.isEmpty,
               let category = categories.first(where: { $0.name == categoryName }) {
                // Enhanced display if we match a category object
                HStack(spacing: 8) {
                    ZStack {
                        Circle()
                            .fill(Color(hex: category.colorHex ?? "#999999"))
                            .frame(width: 24, height: 24)
                        
                        if category.iconType == "sfSymbol" {
                            Image(systemName: category.iconValue ?? "questionmark")
                                .font(.system(size: 12))
                                .foregroundColor(.white)
                        } else {
                            Text(category.iconValue ?? "?")
                                .font(.system(size: 12))
                        }
                    }
                    
                    Text(categoryName)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.primary)
                }
            } else {
                // Fallback text only
                Text(receipt.merchantCategory?.isEmpty == false ? receipt.merchantCategory! : "Uncategorized")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.primary)
            }
        }
        .padding(16)
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
            // NotificationCenter.default.post(name: .receiptSaved, object: nil) // Removed
        } catch {
            print("Error saving note: \(error)")
        }
    }
    
    private var receiptImageSection: some View {
        Group {
            if let imagePath = receipt.imagePath,
               let uiImage = FileStorageService.shared.loadReceiptImage(filename: imagePath) {
                // Existing Image
                VStack(alignment: .leading, spacing: 16) {
                    Text("Receipt Image")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.primary)
                        .padding(.horizontal, 4)
                    
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFit()
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
                }
            } else if shouldShowAddReceiptButton {
                // Add Receipt Button
                Button(action: {
                    checkCameraPermission()
                }) {
                    HStack {
                        Image(systemName: "camera.fill")
                        Text("Attach Receipt Image")
                            .fontWeight(.medium)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
                .padding(.horizontal, 4)
            }
        }
    }
    
    private var shouldShowAddReceiptButton: Bool {
        guard receipt.imagePath == nil else { return false }
        
        // Show for manual or voice entries
        let method = receipt.captureMethod?.lowercased() ?? "manual"
        return method == "manual" || method == "voice"
    }
}

private let dateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .medium
    formatter.timeStyle = .short
    return formatter
}()
