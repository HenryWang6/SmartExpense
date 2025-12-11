import Foundation

extension Notification.Name {
    /// Notification posted when a receipt is saved or updated
    static let receiptSaved = Notification.Name("receiptSaved")
    
    /// Notification posted when a category is created, updated, or deleted
    static let categoryUpdated = Notification.Name("categoryUpdated")
}
