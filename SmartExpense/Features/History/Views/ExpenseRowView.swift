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
            // Icon
            ZStack {
                Circle()
                    .fill(Color.accentColor.opacity(0.15))
                    .frame(width: 44, height: 44)
                
                Image(systemName: iconName(for: receipt))
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.accentColor)
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
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.accentColor)
            
            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.secondary.opacity(0.5))
        }
        .padding(.vertical, 8)
    }
    
    private func iconName(for receipt: Receipt) -> String {
        // Check new captureMethod field first, fall back to isVoiceInput for backward compatibility
        if let method = receipt.captureMethod {
            switch method {
            case "camera", "photoLibrary":
                return "camera.fill"
            case "manual":
                return "hand.draw.fill"
            case "voice":
                return "mic.fill"
            default:
                return "receipt"
            }
        } else if receipt.isVoiceInput {
            return "mic.fill"
        } else if receipt.imagePath != nil {
            return "camera.fill"
        } else {
            return "hand.draw.fill"
        }
    }
}
