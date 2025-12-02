//
//  ReceiptEditViewModel.swift
//  SmartExpense
//
//  Created by Henry Wang on 2025-11-29.
//

import SwiftUI
import CoreData
import Combine

@MainActor
class ReceiptEditViewModel: ObservableObject {
    @Published var merchantName: String
    @Published var date: Date
    @Published var totalAmount: String
    @Published var items: [EditableLineItem]
    @Published var imagePath: String?
    @Published var isVoiceInput: Bool
    
    @Published var showingError = false
    @Published var errorMessage = ""
    
    private let viewContext: NSManagedObjectContext
    private let receiptImage: UIImage?
    
    init(
        extractedData: ExtractedReceiptData? = nil,
        image: UIImage? = nil,
        isVoiceInput: Bool = false,
        viewContext: NSManagedObjectContext
    ) {
        self.viewContext = viewContext
        self.receiptImage = image
        self.isVoiceInput = isVoiceInput
        
        // Initialize from extracted data or defaults
        self.merchantName = extractedData?.merchantName ?? ""
        self.date = extractedData?.date ?? Date()
        self.totalAmount = extractedData?.totalAmount.map { String(format: "%.2f", $0) } ?? ""
        self.items = extractedData?.items.map { EditableLineItem(from: $0) } ?? []
        
        // If no items, add one empty item
        if self.items.isEmpty {
            self.items.append(EditableLineItem())
        }
    }
    
    // MARK: - Item Management
    
    func addItem() {
        items.append(EditableLineItem())
    }
    
    func removeItem(at index: Int) {
        guard items.count > 1 else { return }
        items.remove(at: index)
    }
    
    func moveItem(from source: IndexSet, to destination: Int) {
        items.move(fromOffsets: source, toOffset: destination)
    }
    
    // MARK: - Validation
    
    func validate() -> Bool {
        // Merchant name is required
        if merchantName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            errorMessage = "Merchant name is required"
            showingError = true
            return false
        }
        
        // Total amount is required and must be valid
        guard let amount = Double(totalAmount), amount > 0 else {
            errorMessage = "Please enter a valid total amount"
            showingError = true
            return false
        }
        
        return true
    }
    
    // MARK: - Save
    
    func save() async -> Bool {
        guard validate() else {
            return false
        }
        
        // Save image if present
        var savedImagePath: String?
        if let image = receiptImage {
            savedImagePath = FileStorageService.shared.saveReceiptImage(image)
        }
        
        // Create Receipt entity
        let receipt = Receipt(context: viewContext)
        receipt.id = UUID()
        receipt.merchantName = merchantName.trimmingCharacters(in: .whitespacesAndNewlines)
        receipt.date = date
        receipt.totalAmount = Double(totalAmount) ?? 0
        receipt.imagePath = savedImagePath
        receipt.isVoiceInput = isVoiceInput
        receipt.createdAt = Date()
        receipt.updatedAt = Date()
        
        // Create ReceiptItem entities
        for (index, item) in items.enumerated() {
            if !item.description.isEmpty {
                let receiptItem = ReceiptItem(context: viewContext)
                receiptItem.id = UUID()
                receiptItem.itemDescription = item.description
                receiptItem.quantity = item.quantity
                receiptItem.unitPrice = item.unitPrice
                receiptItem.subtotal = item.subtotal
                receiptItem.sortOrder = Int16(index)
                receiptItem.receipt = receipt
            }
        }
        
        // Save context
        do {
            try viewContext.save()
            return true
        } catch {
            errorMessage = "Failed to save receipt: \(error.localizedDescription)"
            showingError = true
            return false
        }
    }
    
    // MARK: - Calculated Total
    
    var calculatedTotal: Double {
        items.reduce(0) { $0 + $1.subtotal }
    }
    
    var calculatedTotalText: String {
        String(format: "$%.2f", calculatedTotal)
    }
}

// MARK: - Editable Line Item

struct EditableLineItem: Identifiable {
    let id = UUID()
    var description: String
    var quantity: Double
    var unitPrice: Double
    var subtotal: Double
    
    init(
        description: String = "",
        quantity: Double = 1.0,
        unitPrice: Double = 0.0,
        subtotal: Double = 0.0
    ) {
        self.description = description
        self.quantity = quantity
        self.unitPrice = unitPrice
        self.subtotal = subtotal
    }
    
    init(from extracted: ExtractedLineItem) {
        self.description = extracted.description
        self.quantity = extracted.quantity ?? 1.0
        self.unitPrice = extracted.unitPrice ?? 0.0
        self.subtotal = extracted.subtotal ?? 0.0
    }
}
