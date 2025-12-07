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
    
    @State private var captureState: CaptureState = .menu
    @State private var selectedImage: UIImage?
    @State private var extractedData: ExtractedReceiptData?
    @State private var voiceTranscription: String = ""
    @State private var showCameraUnavailableAlert = false
    @State private var captureMethod: String = "manual"
    
    enum CaptureState {
        case menu
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
            case .menu:
                CaptureMenuView { option in
                    handleOptionSelected(option)
                }
                
            case .camera, .photoLibrary:
                // Empty view - camera/photo library presented via fullScreenCover
                Color.clear
                
            case .imagePreview:
                if let image = selectedImage {
                    ImagePreviewView(
                        image: image,
                        onRetake: {
                            captureState = .menu
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
                        captureState = .menu
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
                        date: Date(),
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
            get: { captureState == .camera },
            set: { isPresented in
                if !isPresented && captureState == .camera {
                    captureState = .menu
                }
            }
        )) {
            DocumentScannerView { image in
                selectedImage = image
                captureState = .imagePreview
            }
            .ignoresSafeArea()
        }
        .fullScreenCover(isPresented: Binding(
            get: { captureState == .photoLibrary },
            set: { isPresented in
                if !isPresented && captureState == .photoLibrary {
                    captureState = .menu
                }
            }
        )) {
            ImagePickerView(sourceType: .photoLibrary) { image in
                selectedImage = image
                captureState = .imagePreview
            }
        }
        .alert("Camera Not Available", isPresented: $showCameraUnavailableAlert) {
            Button("Use Photo Library", role: .none) {
                captureState = .photoLibrary
            }
            Button("Cancel", role: .cancel) {
                captureState = .menu
            }
        } message: {
            Text("The camera is not available on the simulator. Please use the photo library option or test on a real device.")
        }
    }
    
    private func handleOptionSelected(_ option: CaptureOption) {
        switch option {
        case .camera:
            captureMethod = "camera"
            checkCameraPermissionAndProceed()
        case .voice:
            captureMethod = "voice"
            captureState = .voiceRecording
        case .manual:
            captureMethod = "manual"
            // For now, go directly to receipt edit with empty data
            captureState = .receiptEdit
        }
    }
    
    private func checkCameraPermissionAndProceed() {
        // First check if camera is available (not available on simulator)
        guard UIImagePickerController.isSourceTypeAvailable(.camera) else {
            showCameraUnavailableAlert = true
            return
        }
        
        Task {
            let status = PermissionsManager.shared.checkCameraPermission()
            
            if status == .authorized {
                // Camera already authorized, present immediately
                await MainActor.run {
                    captureState = .camera
                }
            } else if status == .notDetermined {
                // Request permission
                let granted = await PermissionsManager.shared.requestCameraPermission()
                
                if granted {
                    // Add small delay to ensure view hierarchy is ready after permission dialog
                    try? await Task.sleep(nanoseconds: 300_000_000) // 0.3 seconds
                    
                    await MainActor.run {
                        captureState = .camera
                    }
                } else {
                    await MainActor.run {
                        dismiss()
                    }
                }
            } else {
                // Permission denied - show alert or dismiss
                await MainActor.run {
                    dismiss()
                }
            }
        }
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
    CaptureCoordinatorView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
