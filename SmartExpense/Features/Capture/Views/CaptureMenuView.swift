//
//  CaptureMenuView.swift
//  SmartExpense
//
//  Created by Henry Wang on 2025-11-29.
//

import SwiftUI

struct CaptureMenuView: View {
    @Environment(\.dismiss) private var dismiss
    let onOptionSelected: (CaptureOption) -> Void
    
    @State private var isAnimating = false
    
    var body: some View {
        ZStack {
            // Background dimming
            Color.black.opacity(0.3)
                .ignoresSafeArea()
                .onTapGesture {
                    dismissMenu()
                }
            
            VStack {
                Spacer()
                
                menuContent
                    .padding(.horizontal, 20)
                    .padding(.bottom, 40)
                    .offset(y: isAnimating ? 0 : 400)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                isAnimating = true
            }
        }
    }
    
    private var menuContent: some View {
        VStack(spacing: 16) {
            // Header
            HStack {
                Text("Add Expense")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
                
                Spacer()
                
                Button(action: dismissMenu) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 28))
                        .foregroundColor(.secondary.opacity(0.6))
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 24)
            .padding(.bottom, 8)
            
            // Options
            VStack(spacing: 12) {
                ForEach(CaptureOption.allCases) { option in
                    CaptureOptionCard(option: option) {
                        handleOptionSelection(option)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 20)
        }
        .background(
            RoundedRectangle(cornerRadius: 32, style: .continuous)
                .fill(.regularMaterial)
                .shadow(color: Color.black.opacity(0.2), radius: 30, x: 0, y: -10)
        )
    }
    
    private func handleOptionSelection(_ option: CaptureOption) {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            isAnimating = false
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            // Don't dismiss - let the parent coordinator manage the transition
            // The menu will naturally disappear when captureState changes
            onOptionSelected(option)
        }
    }
    
    private func dismissMenu() {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            isAnimating = false
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            dismiss()
        }
    }
}

struct CaptureOptionCard: View {
    let option: CaptureOption
    let action: () -> Void
    
    @State private var isPressed = false
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                // Icon
                ZStack {
                    Circle()
                        .fill(option.accentColor.opacity(0.15))
                        .frame(width: 56, height: 56)
                    
                    Image(systemName: option.icon)
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundColor(option.accentColor)
                }
                
                // Text
                VStack(alignment: .leading, spacing: 4) {
                    Text(option.title)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.primary)
                    
                    Text(option.description)
                        .font(.system(size: 14, weight: .regular))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Chevron
                Image(systemName: "chevron.right")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.secondary.opacity(0.5))
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .stroke(option.accentColor.opacity(0.2), lineWidth: 1)
                    )
            )
            .scaleEffect(isPressed ? 0.97 : 1.0)
        }
        .buttonStyle(PlainButtonStyle())
        .pressEvents {
            withAnimation(.spring(response: 0.2, dampingFraction: 0.6)) {
                isPressed = true
            }
        } onRelease: {
            withAnimation(.spring(response: 0.2, dampingFraction: 0.6)) {
                isPressed = false
            }
        }
    }
}

// Helper for press animations
extension View {
    func pressEvents(onPress: @escaping () -> Void, onRelease: @escaping () -> Void) -> some View {
        self.simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in onPress() }
                .onEnded { _ in onRelease() }
        )
    }
}

#Preview {
    CaptureMenuView { option in
        print("Selected: \(option.title)")
    }
}
