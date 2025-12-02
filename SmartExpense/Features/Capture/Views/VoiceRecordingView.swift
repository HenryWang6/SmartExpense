//
//  VoiceRecordingView.swift
//  SmartExpense
//
//  Created by Henry Wang on 2025-11-29.
//

import SwiftUI

struct VoiceRecordingView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var speechService = SpeechRecognitionService()
    
    let onComplete: (String) -> Void
    
    @State private var recordingDuration: TimeInterval = 0
    @State private var timer: Timer?
    @State private var showError = false
    @State private var errorMessage = ""
    
    private let maxDuration: TimeInterval = 60
    
    var body: some View {
        ZStack {
            // Background
            LinearGradient(
                colors: [
                    Color(.systemBackground),
                    Color(.systemGray6).opacity(0.3)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            VStack(spacing: 40) {
                Spacer()
                
                // Title
                VStack(spacing: 12) {
                    Text(speechService.isRecording ? "Listening..." : "Voice Expense")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                    
                    Text(speechService.isRecording ? "Speak clearly" : "Tap to start recording")
                        .font(.system(size: 16, weight: .regular))
                        .foregroundColor(.secondary)
                }
                
                // Microphone button
                microphoneButton
                
                // Timer
                if speechService.isRecording {
                    Text(formatDuration(recordingDuration))
                        .font(.system(size: 20, weight: .semibold, design: .monospaced))
                        .foregroundColor(.orange)
                }
                
                // Transcription
                if !speechService.transcription.isEmpty {
                    transcriptionCard
                }
                
                // Hint text
                if !speechService.isRecording && speechService.transcription.isEmpty {
                    hintText
                }
                
                Spacer()
                
                // Bottom buttons
                bottomButtons
                    .padding(.bottom, 40)
            }
            .padding(.horizontal, 24)
        }
        .alert("Error", isPresented: $showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
    }
    
    private var microphoneButton: some View {
        Button(action: toggleRecording) {
            ZStack {
                Circle()
                    .fill(
                        speechService.isRecording
                            ? Color.orange.opacity(0.2)
                            : Color.orange.opacity(0.1)
                    )
                    .frame(width: 160, height: 160)
                    .scaleEffect(speechService.isRecording ? 1.1 : 1.0)
                    .animation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true), value: speechService.isRecording)
                
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.orange,
                                Color.orange.opacity(0.8)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 120, height: 120)
                    .shadow(color: Color.orange.opacity(0.4), radius: 20, x: 0, y: 10)
                
                Image(systemName: speechService.isRecording ? "stop.fill" : "mic.fill")
                    .font(.system(size: 48, weight: .semibold))
                    .foregroundColor(.white)
            }
        }
    }
    
    private var transcriptionCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Transcription")
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.secondary)
                .textCase(.uppercase)
                .tracking(0.5)
            
            Text(speechService.transcription)
                .font(.system(size: 16, weight: .regular))
                .foregroundColor(.primary)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(.ultraThinMaterial)
                .shadow(color: Color.black.opacity(0.06), radius: 16, x: 0, y: 8)
        )
    }
    
    private var hintText: some View {
        VStack(spacing: 12) {
            Text("Try saying:")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.secondary)
            
            VStack(alignment: .leading, spacing: 8) {
                HintRow(text: "\"$45 at Starbucks for coffee\"")
                HintRow(text: "\"Spent 23 dollars at Walmart\"")
                HintRow(text: "\"Uber ride for $18\"")
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(.ultraThinMaterial)
        )
    }
    
    private var bottomButtons: some View {
        HStack(spacing: 16) {
            Button(action: { dismiss() }) {
                Text("Cancel")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(.ultraThinMaterial)
                    )
            }
            
            if !speechService.transcription.isEmpty {
                Button(action: completeRecording) {
                    Text("Continue")
                        .font(.system(size: 17, weight: .bold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .fill(
                                    LinearGradient(
                                        colors: [Color.orange, Color.orange.opacity(0.8)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .shadow(color: Color.orange.opacity(0.4), radius: 20, x: 0, y: 10)
                        )
                }
            }
        }
    }
    
    private func toggleRecording() {
        if speechService.isRecording {
            stopRecording()
        } else {
            startRecording()
        }
    }
    
    private func startRecording() {
        Task {
            do {
                try await speechService.startRecording()
                startTimer()
            } catch {
                errorMessage = error.localizedDescription
                showError = true
            }
        }
    }
    
    private func stopRecording() {
        Task {
            await speechService.stopRecording()
            stopTimer()
        }
    }
    
    private func completeRecording() {
        if speechService.isRecording {
            stopRecording()
        }
        onComplete(speechService.transcription)
    }
    
    private func startTimer() {
        recordingDuration = 0
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            recordingDuration += 0.1
            
            if recordingDuration >= maxDuration {
                stopRecording()
            }
        }
    }
    
    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

struct HintRow: View {
    let text: String
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "quote.bubble")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.orange)
            
            Text(text)
                .font(.system(size: 14, weight: .regular))
                .foregroundColor(.secondary)
        }
    }
}

#Preview {
    VoiceRecordingView { transcription in
        print("Transcription: \(transcription)")
    }
}
