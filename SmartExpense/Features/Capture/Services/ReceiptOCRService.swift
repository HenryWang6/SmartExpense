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
    
    // Internal for testing
    func parseReceiptText(_ lines: [String]) -> ExtractedReceiptData {
        var merchantName: String?
        var date: Date?
        var totalAmount: Double?
        let items: [ExtractedLineItem] = [] // Line item extraction disabled for now
        var confidence: ExtractionConfidence = .low
        
        // Extract merchant name
        merchantName = extractMerchantName(from: lines)
        
        // Extract date and time
        date = extractDate(from: lines)
        
        // Extract total amount
        totalAmount = extractTotalAmount(from: lines)
        
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
    
    func extractMerchantName(from lines: [String]) -> String? {
        // Common noise phrases on receipts - use substring matching
        let invalidKeywords = [
            "customer copy", "merchant copy", "receipt", "welcome", "copy", "duplicate", "credit card"
        ]
        
        for line in lines.prefix(7) {
            let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
            let lowerTrimmed = trimmed.lowercased()
            
            // Skip empty or very short lines
            if trimmed.count <= 2 { continue }
            
            // Skip lines that are mostly numbers or symbols (phone numbers, dates, IDs)
            let letterCount = trimmed.filter { $0.isLetter }.count
            if letterCount < trimmed.count / 2 { continue }

            // Check if line contains any invalid keywords
            var isInvalid = false
            for keyword in invalidKeywords {
                if lowerTrimmed.contains(keyword) {
                    isInvalid = true
                    break
                }
            }
            if isInvalid { continue }
            
            return trimmed
        }
        return nil
    }
    
    func extractDate(from lines: [String]) -> Date? {
        var dateComponent: Date?
        var timeComponent: DateComponents?
        
        // Date Patterns
        let datePatterns = [
             #"(?i)\b(?:Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)[a-z]*\.?\s+\d{1,2}(?:st|nd|rd|th)?,?\s+\d{4}\b"#,
             #"\b\d{1,2}[/.-]\d{1,2}[/.-]\d{2,4}\b"#,
             #"\b\d{4}[/.-]\d{1,2}[/.-]\d{1,2}\b"#
        ]
        
        // Time Patterns
        // Matches HH:MM AM/PM or HH:MM:SS
        let timePattern = #"\b\d{1,2}:\d{2}(?::\d{2})?\s*(?:[AaPp][Mm])?\b"#
        
        for line in lines {
            // Find Date
            if dateComponent == nil {
                for pattern in datePatterns {
                    if let match = findMatch(in: line, pattern: pattern), let date = parseDateString(match) {
                        dateComponent = date
                        break
                    }
                }
            }
            
            // Find Time
            if timeComponent == nil {
                if let match = findMatch(in: line, pattern: timePattern), let time = parseTimeString(match) {
                    timeComponent = time
                }
            }
            
            if dateComponent != nil && timeComponent != nil { break }
        }
        
        // Combine
        if let date = dateComponent {
            var calendar = Calendar.current
            var components = calendar.dateComponents([.year, .month, .day], from: date)
            if let time = timeComponent {
                components.hour = time.hour
                components.minute = time.minute
                components.second = time.second
            }
            return calendar.date(from: components)
        }
        
        return nil
    }
    
    func extractTotalAmount(from lines: [String]) -> Double? {
        let totalKeywords = ["total", "balance", "amount due", "final", "payment", "grand total"]
        let priceRegex = #"\$?\s?(\d{1,3}(?:,\d{3})*\.\d{2})"#
        
        var candidateAmounts: [Double] = []
        var explicitTotal: Double?
        
        // Search from bottom up
        for (index, line) in lines.enumerated().reversed() {
            let lowerLine = line.lowercased()
             
            if let amount = extractPrice(from: line, regex: priceRegex) {
                candidateAmounts.append(amount)
                
                // Check if this line is a "True Total" line
                let isTotalLine = totalKeywords.contains { lowerLine.contains($0) }
                
                // Check immediate previous line (visually above) for keyword
                // Since we iterate reversed, visual above is index - 1
                var contextHasTotal = false
                if index > 0 {
                    let prevLine = lines[index - 1].lowercased()
                    contextHasTotal = totalKeywords.contains { prevLine.contains($0) }
                }
                
                if isTotalLine || contextHasTotal {
                    explicitTotal = amount
                    break // Found explicit total near bottom, likely correct
                }
            }
        }
        
        if let total = explicitTotal {
            return total
        }
        
        // Fallback: Return max value found
        return candidateAmounts.max()
    }
    
    // MARK: - Helpers

    private func findMatch(in text: String, pattern: String) -> String? {
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return nil }
        let range = NSRange(location: 0, length: text.utf16.count)
        if let match = regex.firstMatch(in: text, options: [], range: range) {
             if let range = Range(match.range, in: text) {
                 return String(text[range])
             }
        }
        return nil
    }
    
    private func parseDateString(_ dateString: String) -> Date? {
        // Use NSDataDetector
        guard let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.date.rawValue) else { return nil }
        let matches = detector.matches(in: dateString, options: [], range: NSRange(location: 0, length: dateString.utf16.count))
        return matches.first?.date
    }
    
    private func parseTimeString(_ timeString: String) -> DateComponents? {
        // Mock a date to parse time
        let tempString = "2025-01-01 " + timeString
        if let date = parseDateString(tempString) {
            return Calendar.current.dateComponents([.hour, .minute, .second], from: date)
        }
        return nil
    }
    
    private func extractPrice(from text: String, regex pattern: String) -> Double? {
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return nil }
        let range = NSRange(location: 0, length: text.utf16.count)
        let matches = regex.matches(in: text, options: [], range: range)
        
        // Usually the last match on a line is the final price (e.g. "Total ... $12.34")
        if let lastMatch = matches.last {
             if lastMatch.numberOfRanges > 1 {
                 let range = lastMatch.range(at: 1)
                 if let swiftRange = Range(range, in: text) {
                     var amountStr = String(text[swiftRange])
                     amountStr = amountStr.replacingOccurrences(of: ",", with: "")
                     return Double(amountStr)
                 }
             }
        }
        return nil
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
