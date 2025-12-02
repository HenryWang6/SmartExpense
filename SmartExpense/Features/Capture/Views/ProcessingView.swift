//
//  ProcessingView.swift
//  SmartExpense
//
//  Created by Henry Wang on 2025-11-29.
//

import SwiftUI

struct ProcessingView: View {
    let image: UIImage?
    let onCancel: () -> Void
    
    @State private var rotationAngle: Double = 0
    
    var body: some View {
        ZStack {
            // Blurred background image
            if let image = image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .blur(radius: 20)
                    .ignoresSafeArea()
                    .overlay(
                        Color.black.opacity(0.5)
                            .ignoresSafeArea()
                    )
            } else {
                Color.black.opacity(0.7)
                    .ignoresSafeArea()
            }
            
            // Processing card
            VStack(spacing: 24) {
                // Animated spinner
                ZStack {
                    Circle()
                        .stroke(Color.white.opacity(0.2), lineWidth: 4)
                        .frame(width: 80, height: 80)
                    
                    Circle()
                        .trim(from: 0, to: 0.7)
                        .stroke(
                            LinearGradient(
                                colors: [.green, .green.opacity(0.5)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            style: StrokeStyle(lineWidth: 4, lineCap: .round)
                        )
                        .frame(width: 80, height: 80)
                        .rotationEffect(.degrees(rotationAngle))
                }
                .onAppear {
                    withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                        rotationAngle = 360
                    }
                }
                
                VStack(spacing: 12) {
                    Text("Processing Receipt")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    
                    Text("Extracting receipt information...")
                        .font(.system(size: 16, weight: .regular))
                        .foregroundColor(.white.opacity(0.8))
                        .multilineTextAlignment(.center)
                }
                
                // Cancel button
                Button(action: onCancel) {
                    Text("Cancel")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white.opacity(0.9))
                        .padding(.horizontal, 32)
                        .padding(.vertical, 12)
                        .background(
                            Capsule()
                                .fill(.ultraThinMaterial)
                        )
                }
                .padding(.top, 8)
            }
            .padding(40)
            .background(
                RoundedRectangle(cornerRadius: 32, style: .continuous)
                    .fill(.regularMaterial)
                    .shadow(color: Color.black.opacity(0.3), radius: 40, x: 0, y: 20)
            )
            .padding(.horizontal, 40)
        }
    }
}

#Preview {
    ProcessingView(
        image: UIImage(systemName: "photo"),
        onCancel: { print("Cancelled") }
    )
}
