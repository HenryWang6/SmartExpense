//
//  CaptureCoordinatorView.swift
//  SmartExpense
//
//  Created by Henry Wang on 2025-11-29.
//

import SwiftUI
import CoreData

struct CaptureCoordinatorView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.managedObjectContext) private var viewContext
    
    @State private var captureState: CaptureState
    @State private var selectedImage: UIImage?
    @State private var extractedData: ExtractedReceiptData?
    @State private var voiceTranscription: String = ""
    @State private var showCameraUnavailableAlert = false
    @State private var captureMethod: String
    
    let initialMode: CaptureOption
    
    init(initialMode: CaptureOption) {
        print("DEBUG: CaptureCoordinatorView init with mode: \(initialMode)")
        self.initialMode = initialMode
        _captureMethod = State(initialValue: initialMode.rawValue)
        
        // Set initial state based on mode
        switch initialMode {
        case .camera:
            print("DEBUG: Setting initial state to .camera")
            _captureState = State(initialValue: .camera)
        case .voice:
            _captureState = State(initialValue: .voiceRecording)
        case .manual:
            _captureState = State(initialValue: .receiptEdit)
        }
    }
    
    enum CaptureState {
        // case menu // Removed
        case camera
        case photoLibrary
        case imagePreview
        case processing
        case receiptEdit
        case voiceRecording
        case voiceReview
    }
    
    var body: some View {
        Group {
            switch captureState {
            // Case menu removed
                
            case .camera:
                DocumentScannerView(
                    onImageCaptured: { image in
                        selectedImage = image
                        captureState = .imagePreview
                    },
                    onCancel: {
                        dismiss()
                    }
                )
                .ignoresSafeArea()

            case .photoLibrary:
                // Empty view - photo library presented via fullScreenCover
                Color.clear
                
            case .imagePreview:
                if let image = selectedImage {
                    ImagePreviewView(
                        image: image,
                        onRetake: {
                            // Reset to initial state or camera
                            if initialMode == .camera {
                                captureState = .camera
                            } else {
                                // Fallback or dismiss?
                                dismiss()
                            }
                        },
                        onProcess: {
                            captureState = .processing
                            processImage(image)
                        }
                    )
                }
                
            case .processing:
                ProcessingView(
                    image: selectedImage,
                    onCancel: {
                        dismiss()
                    }
                )
                
            case .receiptEdit:
                ReceiptReviewView(
                    viewModel: ReceiptReviewViewModel(
                        extractedData: extractedData,
                        image: selectedImage,
                        isVoiceInput: captureMethod == "voice",
                        voiceTranscript: captureMethod == "voice" ? voiceTranscription : nil,
                        captureMethod: captureMethod,
                        viewContext: viewContext
                    )
                )
                .onDisappear {
                    dismiss()
                }
                
            case .voiceRecording:
                VoiceRecordingView { transcription in
                    voiceTranscription = transcription
                    // Parse the transcription
                    let parsed = VoiceExpenseParser.parse(transcription)
                    extractedData = ExtractedReceiptData(
                        merchantName: parsed.merchant ?? "",
                        date: parsed.date ?? Date(),
                        totalAmount: parsed.amount,
                        items: [],
                        confidence: .medium
                    )
                    captureState = .receiptEdit
                }
                
            case .voiceReview:
                // This case is now unused, but kept for compatibility
                ReceiptReviewView(
                    viewModel: ReceiptReviewViewModel(
                        extractedData: extractedData,
                        image: nil,
                        isVoiceInput: true,
                        voiceTranscript: voiceTranscription,
                        captureMethod: "voice",
                        viewContext: viewContext
                    )
                )
                .onDisappear {
                    dismiss()
                }
            }
        }
        .fullScreenCover(isPresented: Binding(
            get: { captureState == .photoLibrary },
            set: { isPresented in
                // Handled by onCancel/dismiss
            }
        )) {
            ImagePickerView(
                sourceType: .photoLibrary,
                onImageSelected: { image in
                    selectedImage = image
                    captureState = .imagePreview
                },
                onCancel: {
                    print("DEBUG: ImagePickerView cancelled. Scheduling delayed dismiss.")
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        print("DEBUG: Executing delayed dismiss for Coordinator.")
                        dismiss()
                    }
                }
            )
        }
        .alert("Camera Not Available", isPresented: $showCameraUnavailableAlert) {
            Button("Use Photo Library", role: .none) {
                captureState = .photoLibrary
            }
        } message: {
            Text("The camera is not available on the simulator. Please use the photo library option or test on a real device.")
        }
        // onAppear startOption logic removed
    }
    

    
    private func processImage(_ image: UIImage) {
        Task {
            do {
                let data = try await ReceiptOCRService.shared.extractReceiptData(from: image)
                await MainActor.run {
                    extractedData = data
                    captureState = .receiptEdit
                }
            } catch {
                // If OCR fails, still allow manual entry
                await MainActor.run {
                    extractedData = ExtractedReceiptData()
                    captureState = .receiptEdit
                }
            }
        }
    }
}

#Preview {
    CaptureCoordinatorView(initialMode: .manual)
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
