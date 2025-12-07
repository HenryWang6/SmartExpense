//
//  VoiceExpenseParser.swift
//  SmartExpense
//
//  Created by Henry Wang on 2025-11-29.
//

import Foundation

struct VoiceExpenseParser {
    /// Parse voice transcription to extract amount, merchant, and date
    static func parse(_ transcription: String) -> (amount: Double?, merchant: String?, date: Date?) {
        let amount = extractAmount(from: transcription)
        let merchant = extractMerchant(from: transcription)
        let date = extractDate(from: transcription)
        
        return (amount, merchant, date)
    }
    
    // MARK: - Amount Extraction
    
    private static func extractAmount(from text: String) -> Double? {
        let lowercased = text.lowercased()
        
        // Common patterns for amount extraction (ordered by specificity)
        let patterns = [
            // Pattern 1: "spent/paid/cost $XX.XX" or "$XX.XX"
            #"(?:spent|paid|cost|was|for|total)?\s*\$\s*(\d+(?:\.\d{1,2})?)"#,
            
            // Pattern 2: "XX.XX dollars/bucks"
            #"(\d+(?:\.\d{1,2})?)\s*(?:dollars?|bucks)"#,
            
            // Pattern 3: "XX dollars and XX cents"
            #"(\d+)\s*dollars?\s*(?:and\s*(\d+)\s*cents?)?"#,
            
            // Pattern 4: Just numbers followed by common keywords
            #"(?:spent|paid|cost|was|total)\s+(?:about\s+)?(\d+(?:\.\d{1,2})?)"#,
        ]
        
        for pattern in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) {
                let nsString = text as NSString
                let matches = regex.matches(in: text, range: NSRange(location: 0, length: nsString.length))
                
                if let match = matches.first {
                    // Handle "XX dollars and YY cents" pattern
                    if match.numberOfRanges > 2 && match.range(at: 2).location != NSNotFound {
                        let dollarsRange = match.range(at: 1)
                        let centsRange = match.range(at: 2)
                        
                        if let dollars = Double(nsString.substring(with: dollarsRange)),
                           let cents = Double(nsString.substring(with: centsRange)) {
                            return dollars + (cents / 100.0)
                        }
                    }
                    
                    // Handle standard patterns
                    if match.numberOfRanges > 1 {
                        let amountRange = match.range(at: 1)
                        let amountString = nsString.substring(with: amountRange)
                        if let amount = Double(amountString) {
                            return amount
                        }
                    }
                }
            }
        }
        
        // Fallback: Spelled out numbers (basic support)
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
    
    // MARK: - Merchant Extraction
    
    private static func extractMerchant(from text: String) -> String? {
        // Common patterns for merchant extraction (ordered by specificity)
        let merchantPatterns = [
            // Pattern 1: "at [Merchant]" (most common)
            #"(?:at|@)\s+([A-Za-z0-9'\s&-]+?)(?:\s+(?:for|on|today|yesterday|this|last|spent|paid|cost|\$|\d)|\s*$)"#,
            
            // Pattern 2: "from [Merchant]"
            #"from\s+([A-Za-z0-9'\s&-]+?)(?:\s+(?:for|on|today|yesterday|this|last|spent|paid|cost|\$|\d)|\s*$)"#,
            
            // Pattern 3: "[Merchant] for/on"
            #"^([A-Za-z0-9'\s&-]+?)\s+(?:for|on)\s+"#,
            
            // Pattern 4: "bought/purchased at/from [Merchant]"
            #"(?:bought|purchased)\s+(?:at|from)\s+([A-Za-z0-9'\s&-]+?)(?:\s+(?:for|on|today|yesterday|this|last|spent|paid|cost|\$|\d)|\s*$)"#,
        ]
        
        for pattern in merchantPatterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) {
                let nsString = text as NSString
                let matches = regex.matches(in: text, range: NSRange(location: 0, length: nsString.length))
                
                if let match = matches.first, match.numberOfRanges > 1 {
                    let merchantRange = match.range(at: 1)
                    let merchant = nsString.substring(with: merchantRange)
                        .trimmingCharacters(in: .whitespacesAndNewlines)
                    
                    if !merchant.isEmpty && merchant.count > 1 {
                        return merchant.capitalized
                    }
                }
            }
        }
        
        // Fallback: Check for common merchant names
        let commonMerchants = [
            "starbucks", "walmart", "target", "amazon", "whole foods",
            "trader joe's", "trader joes", "costco", "uber", "lyft", "mcdonald's",
            "chipotle", "subway", "dunkin", "dunkin donuts", "cvs", "walgreens",
            "safeway", "kroger", "publix", "aldi", "7-eleven", "shell", "chevron",
            "exxon", "bp", "home depot", "lowe's", "best buy", "apple store",
            "nike", "adidas", "gap", "old navy", "h&m", "zara", "sephora",
            "ulta", "panera", "chick-fil-a", "taco bell", "wendy's", "burger king",
            "pizza hut", "domino's", "papa john's", "olive garden", "red lobster"
        ]
        
        let lowercased = text.lowercased()
        for merchant in commonMerchants {
            if lowercased.contains(merchant) {
                // Return proper capitalization
                return merchant.split(separator: " ")
                    .map { $0.capitalized }
                    .joined(separator: " ")
            }
        }
        
        return nil
    }
    
    // MARK: - Date Extraction
    
    private static func extractDate(from text: String) -> Date? {
        let lowercased = text.lowercased()
        let calendar = Calendar.current
        let now = Date()
        
        // Pattern 1: Relative dates (today, yesterday, etc.)
        if lowercased.contains("today") || lowercased.contains("just now") {
            return now
        }
        
        if lowercased.contains("yesterday") {
            return calendar.date(byAdding: .day, value: -1, to: now)
        }
        
        // Pattern 2: "last [day of week]" or "this [day of week]"
        let weekdays = [
            "monday": 2, "tuesday": 3, "wednesday": 4, "thursday": 5,
            "friday": 6, "saturday": 7, "sunday": 1
        ]
        
        for (day, weekdayNum) in weekdays {
            if lowercased.contains("last " + day) {
                return findLastWeekday(weekdayNum, from: now)
            }
            if lowercased.contains("this " + day) {
                return findThisWeekday(weekdayNum, from: now)
            }
        }
        
        // Pattern 3: "X days ago"
        let daysAgoPattern = #"(\d+)\s*days?\s*ago"#
        if let regex = try? NSRegularExpression(pattern: daysAgoPattern, options: .caseInsensitive),
           let match = regex.firstMatch(in: text, range: NSRange(location: 0, length: text.utf16.count)),
           match.numberOfRanges > 1 {
            let nsString = text as NSString
            let daysString = nsString.substring(with: match.range(at: 1))
            if let days = Int(daysString) {
                return calendar.date(byAdding: .day, value: -days, to: now)
            }
        }
        
        // Pattern 4: Specific date formats
        let datePatterns = [
            // "on December 5th" or "on Dec 5"
            #"on\s+([A-Za-z]+)\s+(\d{1,2})(?:st|nd|rd|th)?"#,
            
            // "December 5th" or "Dec 5"
            #"([A-Za-z]+)\s+(\d{1,2})(?:st|nd|rd|th)?"#,
            
            // "12/5" or "12/05/2025"
            #"(\d{1,2})/(\d{1,2})(?:/(\d{2,4}))?"#,
            
            // "5th of December"
            #"(\d{1,2})(?:st|nd|rd|th)?\s+of\s+([A-Za-z]+)"#,
        ]
        
        for pattern in datePatterns {
            if let date = tryExtractSpecificDate(from: text, pattern: pattern, referenceDate: now) {
                return date
            }
        }
        
        // Default: return current date if no date found
        return now
    }
    
    private static func findLastWeekday(_ weekday: Int, from date: Date) -> Date? {
        let calendar = Calendar.current
        var components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: date)
        components.weekday = weekday
        
        if let targetDate = calendar.date(from: components), targetDate < date {
            return targetDate
        }
        
        // If the day hasn't occurred this week, go back one week
        components.weekOfYear = (components.weekOfYear ?? 0) - 1
        return calendar.date(from: components)
    }
    
    private static func findThisWeekday(_ weekday: Int, from date: Date) -> Date? {
        let calendar = Calendar.current
        var components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: date)
        components.weekday = weekday
        return calendar.date(from: components)
    }
    
    private static func tryExtractSpecificDate(from text: String, pattern: String, referenceDate: Date) -> Date? {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive),
              let match = regex.firstMatch(in: text, range: NSRange(location: 0, length: text.utf16.count)) else {
            return nil
        }
        
        let nsString = text as NSString
        let calendar = Calendar.current
        
        // Handle month/day patterns
        if match.numberOfRanges >= 3 {
            let part1 = nsString.substring(with: match.range(at: 1))
            let part2 = nsString.substring(with: match.range(at: 2))
            
            // Try month name + day
            if let month = monthNumber(from: part1), let day = Int(part2) {
                var components = calendar.dateComponents([.year], from: referenceDate)
                components.month = month
                components.day = day
                
                if let date = calendar.date(from: components) {
                    // If the date is in the future, assume it's from last year
                    if date > referenceDate {
                        components.year = (components.year ?? 0) - 1
                        return calendar.date(from: components)
                    }
                    return date
                }
            }
            
            // Try day + month name (e.g., "5th of December")
            if let day = Int(part1), let month = monthNumber(from: part2) {
                var components = calendar.dateComponents([.year], from: referenceDate)
                components.month = month
                components.day = day
                
                if let date = calendar.date(from: components) {
                    if date > referenceDate {
                        components.year = (components.year ?? 0) - 1
                        return calendar.date(from: components)
                    }
                    return date
                }
            }
            
            // Try numeric month/day
            if let month = Int(part1), let day = Int(part2) {
                var components = calendar.dateComponents([.year], from: referenceDate)
                components.month = month
                components.day = day
                
                // Check if year is provided
                if match.numberOfRanges >= 4 && match.range(at: 3).location != NSNotFound {
                    let yearString = nsString.substring(with: match.range(at: 3))
                    if let year = Int(yearString) {
                        components.year = year < 100 ? 2000 + year : year
                    }
                }
                
                if let date = calendar.date(from: components) {
                    if date > referenceDate && match.numberOfRanges < 4 {
                        components.year = (components.year ?? 0) - 1
                        return calendar.date(from: components)
                    }
                    return date
                }
            }
        }
        
        return nil
    }
    
    private static func monthNumber(from monthString: String) -> Int? {
        let months = [
            "january": 1, "jan": 1,
            "february": 2, "feb": 2,
            "march": 3, "mar": 3,
            "april": 4, "apr": 4,
            "may": 5,
            "june": 6, "jun": 6,
            "july": 7, "jul": 7,
            "august": 8, "aug": 8,
            "september": 9, "sep": 9, "sept": 9,
            "october": 10, "oct": 10,
            "november": 11, "nov": 11,
            "december": 12, "dec": 12
        ]
        
        return months[monthString.lowercased()]
    }
}
