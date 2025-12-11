//
//  ExpenseRowView.swift
//  SmartExpense
//
//  Created by Henry Wang on 2025-12-03.
//

import SwiftUI

private let dateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .medium
    formatter.timeStyle = .none
    return formatter
}()

struct ExpenseRowView: View {
    let receipt: Receipt
    
    var body: some View {
        HStack(spacing: 16) {
            // Icon with Badge
            ZStack(alignment: .bottomTrailing) {
                // Main Category/Merchant Circle
                ZStack {
                    Circle()
                        .fill(categoryColor)
                        .frame(width: 48, height: 48)
                    
                    if let category = receipt.category {
                        if category.iconType == "sfSymbol" {
                            Image(systemName: category.iconValue ?? "questionmark")
                                .font(.system(size: 20)) // Adjust size as needed
                                .foregroundColor(.white)
                        } else {
                            Text(category.iconValue ?? "")
                                .font(.system(size: 20))
                        }
                    } else {
                        Text(merchantInitial)
                            .font(.system(size: 20, weight: .semibold, design: .rounded))
                            .foregroundColor(.accentColor)
                    }
                }
                
                // Input Source Badge
                ZStack {
                    Circle()
                        .fill(Color(UIColor.systemBackground)) // Match background for cutout effect
                        .frame(width: 22, height: 22)
                    
                    Image(systemName: sourceIconInfo.icon)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(sourceIconInfo.color)
                }
                .offset(x: 4, y: 4)
            }
            
            // Content
            VStack(alignment: .leading, spacing: 4) {
                Text(receipt.merchantName ?? "Unknown Merchant")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.primary)
                
                Text(receipt.date ?? Date(), formatter: dateFormatter)
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Text("$\(receipt.totalAmount, specifier: "%.2f")")
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundColor(.accentColor)
        }
        .padding(.vertical, 8)
    }
    
    private var merchantInitial: String {
        guard let name = receipt.merchantName, !name.isEmpty else { return "?" }
        return String(name.prefix(1)).uppercased()
    }
    
    private var sourceIconInfo: (icon: String, color: Color) {
        if let method = receipt.captureMethod {
            switch method {
            case "camera", "photoLibrary":
                return ("camera.fill", .green)
            case "manual":
                return ("square.and.pencil", Color(red: 0.6, green: 0.4, blue: 0.2)) // Warm brown
            case "voice":
                return ("mic.fill", .orange)
            default:
                return ("receipt", .secondary)
            }
        } else if receipt.isVoiceInput {
            return ("mic.fill", .orange)
        } else if receipt.imagePath != nil {
            return ("camera.fill", .green)
        } else {
            return ("square.and.pencil", Color(red: 0.6, green: 0.4, blue: 0.2))
        }
    }
    
    private var categoryColor: Color {
        if let colorHex = receipt.category?.colorHex {
            return Color(hex: colorHex)
        }
        return Color.accentColor.opacity(0.1)
    }
}
