//
//  VoiceExpenseParser.swift
//  SmartExpense
//
//  Created by Henry Wang on 2025-11-29.
//

import Foundation

struct VoiceExpenseParser {
    static func parse(_ transcription: String) -> (amount: Double?, merchant: String?) {
        let amount = extractAmount(from: transcription)
        let merchant = extractMerchant(from: transcription)
        
        return (amount, merchant)
    }
    
    private static func extractAmount(from text: String) -> Double? {
        let lowercased = text.lowercased()
        
        // Pattern 1: $XX.XX or XX dollars
        let patterns = [
            #"\\$\\s*(\\d+(?:\\.\\d{2})?)"#,  // $45.50
            #"(\\d+(?:\\.\\d{2})?)\\s*dollars?"#,  // 45 dollars
            #"(\\d+)\\s*bucks"#  // 45 bucks
        ]
        
        for pattern in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) {
                let nsString = text as NSString
                let matches = regex.matches(in: text, range: NSRange(location: 0, length: nsString.length))
                
                if let match = matches.first, match.numberOfRanges > 1 {
                    let amountRange = match.range(at: 1)
                    let amountString = nsString.substring(with: amountRange)
                    if let amount = Double(amountString) {
                        return amount
                    }
                }
            }
        }
        
        // Pattern 2: Spelled out numbers (basic)
        let numberWords = [
            "one": 1.0, "two": 2.0, "three": 3.0, "four": 4.0, "five": 5.0,
            "six": 6.0, "seven": 7.0, "eight": 8.0, "nine": 9.0, "ten": 10.0,
            "eleven": 11.0, "twelve": 12.0, "thirteen": 13.0, "fourteen": 14.0, "fifteen": 15.0,
            "sixteen": 16.0, "seventeen": 17.0, "eighteen": 18.0, "nineteen": 19.0, "twenty": 20.0,
            "thirty": 30.0, "forty": 40.0, "fifty": 50.0, "sixty": 60.0, "seventy": 70.0,
            "eighty": 80.0, "ninety": 90.0, "hundred": 100.0
        ]
        
        for (word, value) in numberWords {
            if lowercased.contains(word + " dollar") {
                return value
            }
        }
        
        return nil
    }
    
    private static func extractMerchant(from text: String) -> String? {
        let lowercased = text.lowercased()
        
        // Common merchant patterns
        let merchantPatterns = [
            #"at\\s+([A-Za-z\\s]+?)(?:\\s+for|\\s+on|\\s*$)"#,
            #"from\\s+([A-Za-z\\s]+?)(?:\\s+for|\\s+on|\\s*$)"#
        ]
        
        for pattern in merchantPatterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) {
                let nsString = text as NSString
                let matches = regex.matches(in: text, range: NSRange(location: 0, length: nsString.length))
                
                if let match = matches.first, match.numberOfRanges > 1 {
                    let merchantRange = match.range(at: 1)
                    let merchant = nsString.substring(with: merchantRange)
                        .trimmingCharacters(in: .whitespacesAndNewlines)
                    
                    if !merchant.isEmpty {
                        return merchant.capitalized
                    }
                }
            }
        }
        
        // Common merchants list (can be expanded)
        let commonMerchants = [
            "starbucks", "walmart", "target", "amazon", "whole foods",
            "trader joe's", "costco", "uber", "lyft", "mcdonald's",
            "chipotle", "subway", "dunkin", "cvs", "walgreens"
        ]
        
        for merchant in commonMerchants {
            if lowercased.contains(merchant) {
                return merchant.capitalized
            }
        }
        
        return nil
    }
}
