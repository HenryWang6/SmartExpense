//
//  CaptureOption.swift
//  SmartExpense
//
//  Created by Henry Wang on 2025-11-29.
//

import SwiftUI

enum CaptureOption: String, CaseIterable, Identifiable {
    case camera = "camera"
    case voice = "voice"
    case manual = "manual"
    
    var id: String { rawValue }
    
    var title: String {
        switch self {
        case .camera:
            return "Scan Receipt"
        case .voice:
            return "Voice Entry"
        case .manual:
            return "Manual Entry"
        }
    }
    
    var description: String {
        switch self {
        case .camera:
            return "Take a photo or choose from library"
        case .voice:
            return "Record expense with your voice"
        case .manual:
            return "Enter expense details manually"
        }
    }
    
    var icon: String {
        switch self {
        case .camera:
            return "camera.fill"
        case .voice:
            return "mic.fill"
        case .manual:
            return "square.and.pencil"
        }
    }
    
    var accentColor: Color {
        switch self {
        case .camera:
            return .green
        case .voice:
            return .orange
        case .manual:
            return Color(red: 0.6, green: 0.4, blue: 0.2) // Warm brown
        }
    }
}
