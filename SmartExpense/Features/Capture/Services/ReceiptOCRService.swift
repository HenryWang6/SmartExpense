//
//  ReceiptOCRService.swift
//  SmartExpense
//
//  Created by Henry Wang on 2025-11-29.
//

import UIKit
import Vision

class ReceiptOCRService {
    static let shared = ReceiptOCRService()
    
    private init() {}
    
    func extractReceiptData(from image: UIImage) async throws -> ExtractedReceiptData {
        guard let cgImage = image.cgImage else {
            throw OCRError.invalidImage
        }
        
        // Perform text recognition
        let recognizedText = try await recognizeText(from: cgImage)
        
        // Parse the recognized text
        let extractedData = parseReceiptText(recognizedText)
        
        return extractedData
    }
    
    // MARK: - Text Recognition
    
    private func recognizeText(from cgImage: CGImage) async throws -> [String] {
        return try await withCheckedThrowingContinuation { continuation in
            let request = VNRecognizeTextRequest { request, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                
                guard let observations = request.results as? [VNRecognizedTextObservation] else {
                    continuation.resume(throwing: OCRError.noTextFound)
                    return
                }
                
                let recognizedStrings = observations.compactMap { observation in
                    observation.topCandidates(1).first?.string
                }
                
                continuation.resume(returning: recognizedStrings)
            }
            
            request.recognitionLevel = .accurate
            request.usesLanguageCorrection = true
            
            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            
            do {
                try handler.perform([request])
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }
    
    // MARK: - Text Parsing
    
    private func parseReceiptText(_ lines: [String]) -> ExtractedReceiptData {
        var merchantName: String?
        var date: Date?
        var totalAmount: Double?
        var items: [ExtractedLineItem] = []
        var confidence: ExtractionConfidence = .low
        
        // Extract merchant name (usually first few lines with substantial text)
        merchantName = extractMerchantName(from: lines)
        
        // Extract date
        date = extractDate(from: lines)
        
        // Extract total amount
        totalAmount = extractTotalAmount(from: lines)
        
        // Extract line items
//        items = extractLineItems(from: lines)
        
        // Determine confidence
        let fieldsFound = [merchantName != nil, date != nil, totalAmount != nil].filter { $0 }.count
        if fieldsFound >= 3 {
            confidence = .high
        } else if fieldsFound >= 2 {
            confidence = .medium
        } else {
            confidence = .low
        }
        
        return ExtractedReceiptData(
            merchantName: merchantName,
            date: date,
            totalAmount: totalAmount,
            items: items,
            confidence: confidence
        )
    }
    
    private func extractMerchantName(from lines: [String]) -> String? {
        // Look for the first substantial line (more than 3 characters, not a number)
        for line in lines.prefix(5) {
            let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmed.count > 3 && !trimmed.allSatisfy({ $0.isNumber || $0.isPunctuation }) {
                return trimmed
            }
        }
        return nil
    }
    
    private func extractDate(from lines: [String]) -> Date? {
        let datePatterns = [
            "MM/dd/yyyy",
            "MM-dd-yyyy",
            "yyyy-MM-dd",
            "dd/MM/yyyy",
            "MMM dd, yyyy",
            "MMMM dd, yyyy"
        ]
        
        for line in lines {
            for pattern in datePatterns {
                let formatter = DateFormatter()
                formatter.dateFormat = pattern
                formatter.locale = Locale(identifier: "en_US_POSIX")
                
                // Try to find date pattern in the line
                if let date = formatter.date(from: line) {
                    return date
                }
                
                // Try extracting date from parts of the line
                let components = line.components(separatedBy: .whitespaces)
                for component in components {
                    if let date = formatter.date(from: component) {
                        return date
                    }
                }
            }
        }
        
        return nil
    }
    
    private func extractTotalAmount(from lines: [String]) -> Double? {
        let totalKeywords = ["total", "amount due", "balance", "grand total", "amount"]
        
        for (index, line) in lines.enumerated() {
            let lowercased = line.lowercased()
            
            // Check if line contains total keyword
            for keyword in totalKeywords {
                if lowercased.contains(keyword) {
                    // Look for amount in this line or next line
                    if let amount = extractAmount(from: line) {
                        return amount
                    }
                    
                    // Check next line
                    if index + 1 < lines.count {
                        if let amount = extractAmount(from: lines[index + 1]) {
                            return amount
                        }
                    }
                }
            }
        }
        
        // Fallback: look for largest amount in the receipt
        var maxAmount: Double = 0
        for line in lines {
            if let amount = extractAmount(from: line) {
                maxAmount = max(maxAmount, amount)
            }
        }
        
        return maxAmount > 0 ? maxAmount : nil
    }
    
    private func extractAmount(from text: String) -> Double? {
        // Pattern to match currency amounts: $12.34, 12.34, $12, etc.
        let pattern = #"\\$?\\s*(\\d+[,\\d]*\\.?\\d{0,2})"#
        
        guard let regex = try? NSRegularExpression(pattern: pattern) else {
            return nil
        }
        
        let nsString = text as NSString
        let matches = regex.matches(in: text, range: NSRange(location: 0, length: nsString.length))
        
        for match in matches {
            if match.numberOfRanges > 1 {
                let amountRange = match.range(at: 1)
                let amountString = nsString.substring(with: amountRange)
                    .replacingOccurrences(of: ",", with: "")
                
                if let amount = Double(amountString) {
                    return amount
                }
            }
        }
        
        return nil
    }
    
    private func extractLineItems(from lines: [String]) -> [ExtractedLineItem] {
        var items: [ExtractedLineItem] = []
        
        for line in lines {
            // Skip very short lines
            if line.count < 3 {
                continue
            }
            
            // Look for lines with amounts (potential items)
            if let amount = extractAmount(from: line) {
                // Extract description (text before the amount)
                let components = line.components(separatedBy: .whitespaces)
                var description = ""
                
                for component in components {
                    if extractAmount(from: component) == nil {
                        description += component + " "
                    }
                }
                
                description = description.trimmingCharacters(in: .whitespacesAndNewlines)
                
                if !description.isEmpty && description.count > 2 {
                    items.append(ExtractedLineItem(
                        description: description,
                        quantity: 1.0,
                        unitPrice: amount,
                        subtotal: amount
                    ))
                }
            }
        }
        
        // Limit to reasonable number of items
        return Array(items.prefix(20))
    }
}

enum OCRError: LocalizedError {
    case invalidImage
    case noTextFound
    case processingFailed
    
    var errorDescription: String? {
        switch self {
        case .invalidImage:
            return "Invalid image format"
        case .noTextFound:
            return "No text found in the image"
        case .processingFailed:
            return "Failed to process receipt"
        }
    }
}
