//
//  DataService.swift
//  SmartExpense
//
//  Created by Antigravity on 2025-12-12.
//

import CoreData

/// Base protocol for all data services
protocol DataService {
    var context: NSManagedObjectContext { get }
    
    init(context: NSManagedObjectContext)
    
    func save() throws
}

extension DataService {
    func save() throws {
        if context.hasChanges {
            try context.save()
        }
    }
}
