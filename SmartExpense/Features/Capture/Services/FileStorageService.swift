//
//  FileStorageService.swift
//  SmartExpense
//
//  Created by Henry Wang on 2025-11-29.
//

import UIKit

class FileStorageService {
    static let shared = FileStorageService()
    
    private let fileManager = FileManager.default
    private let receiptsDirectory = "Receipts"
    
    private init() {
        createReceiptsDirectoryIfNeeded()
    }
    
    // MARK: - Directory Management
    
    private func createReceiptsDirectoryIfNeeded() {
        guard let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return
        }
        
        let receiptsURL = documentsURL.appendingPathComponent(receiptsDirectory)
        
        if !fileManager.fileExists(atPath: receiptsURL.path) {
            try? fileManager.createDirectory(at: receiptsURL, withIntermediateDirectories: true)
        }
    }
    
    private func getReceiptsDirectoryURL() -> URL? {
        guard let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return nil
        }
        return documentsURL.appendingPathComponent(receiptsDirectory)
    }
    
    // MARK: - Save Image
    
    func saveReceiptImage(_ image: UIImage) -> String? {
        guard let receiptsURL = getReceiptsDirectoryURL() else {
            return nil
        }
        
        // Generate unique filename
        let filename = "\(UUID().uuidString).jpg"
        let fileURL = receiptsURL.appendingPathComponent(filename)
        
        // Compress image to JPEG
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            return nil
        }
        
        // Save to file
        do {
            try imageData.write(to: fileURL)
            return filename
        } catch {
            print("Error saving receipt image: \(error)")
            return nil
        }
    }
    
    // MARK: - Load Image
    
    func loadReceiptImage(filename: String) -> UIImage? {
        guard let receiptsURL = getReceiptsDirectoryURL() else {
            return nil
        }
        
        let fileURL = receiptsURL.appendingPathComponent(filename)
        
        guard let imageData = try? Data(contentsOf: fileURL) else {
            return nil
        }
        
        return UIImage(data: imageData)
    }
    
    // MARK: - Delete Image
    
    func deleteReceiptImage(filename: String) {
        guard let receiptsURL = getReceiptsDirectoryURL() else {
            return
        }
        
        let fileURL = receiptsURL.appendingPathComponent(filename)
        
        try? fileManager.removeItem(at: fileURL)
    }
    
    // MARK: - Get Full Path
    
    func getFullPath(for filename: String) -> String? {
        guard let receiptsURL = getReceiptsDirectoryURL() else {
            return nil
        }
        
        return receiptsURL.appendingPathComponent(filename).path
    }
}
