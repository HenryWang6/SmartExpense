//
//  ExtractedReceiptData.swift
//  SmartExpense
//
//  Created by Henry Wang on 2025-11-29.
//

import Foundation

struct ExtractedReceiptData {
    var merchantName: String?
    var date: Date?
    var totalAmount: Double?
    var items: [ExtractedLineItem]
    var confidence: ExtractionConfidence
    
    init(
        merchantName: String? = nil,
        date: Date? = nil,
        totalAmount: Double? = nil,
        items: [ExtractedLineItem] = [],
        confidence: ExtractionConfidence = .low
    ) {
        self.merchantName = merchantName
        self.date = date
        self.totalAmount = totalAmount
        self.items = items
        self.confidence = confidence
    }
}

struct ExtractedLineItem: Identifiable {
    let id = UUID()
    var description: String
    var quantity: Double?
    var unitPrice: Double?
    var subtotal: Double?
    
    init(
        description: String,
        quantity: Double? = nil,
        unitPrice: Double? = nil,
        subtotal: Double? = nil
    ) {
        self.description = description
        self.quantity = quantity
        self.unitPrice = unitPrice
        self.subtotal = subtotal
    }
}

enum ExtractionConfidence {
    case high
    case medium
    case low
    
    var description: String {
        switch self {
        case .high:
            return "High confidence"
        case .medium:
            return "Medium confidence"
        case .low:
            return "Low confidence"
        }
    }
}
