import Foundation
import CoreData

struct HistoryFilter {
    let category: String?
    let dateRange: (start: Date, end: Date)?
    let receiptId: NSManagedObjectID?
    
    var displayText: String {
        var parts: [String] = []
        
        if let category = category {
            parts.append(category)
        }
        
        if let range = dateRange {
            let formatter = DateFormatter()
            formatter.dateFormat = "MMM yyyy"
            let startText = formatter.string(from: range.start)
            let endText = formatter.string(from: range.end)
            
            if startText == endText {
                parts.append(startText)
            } else {
                parts.append("\(startText) - \(endText)")
            }
        }
        
        return parts.joined(separator: " • ")
    }
}
