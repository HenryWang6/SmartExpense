//
//  DocumentScannerView.swift
//  SmartExpense
//
//  Created by Henry Wang on 2025-12-06.
//

import SwiftUI
import AVFoundation
import Vision
import CoreImage

struct DocumentScannerView: UIViewControllerRepresentable {
    @Environment(\.dismiss) private var dismiss
    
    let onImageCaptured: (UIImage) -> Void
    var onCancel: (() -> Void)? = nil
    
    func makeUIViewController(context: Context) -> ScannerViewController {
        let controller = ScannerViewController()
        controller.delegate = context.coordinator
        return controller
    }
    
    func updateUIViewController(_ uiViewController: ScannerViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, ScannerViewControllerDelegate {
        let parent: DocumentScannerView
        
        init(_ parent: DocumentScannerView) {
            self.parent = parent
        }
        
        func scannerViewControllerDidCapture(_ image: UIImage) {
            parent.onImageCaptured(image)
        }
        
        func scannerViewControllerDidCancel() {
            print("DEBUG: DocumentScannerView coordinator didCancel called.")
            if let onCancel = parent.onCancel {
                print("DEBUG: Calling custom onCancel")
                onCancel()
            } else {
                print("DEBUG: Calling parent.dismiss()")
                parent.dismiss()
            }
        }
    }
}

protocol ScannerViewControllerDelegate: AnyObject {
    func scannerViewControllerDidCapture(_ image: UIImage)
    func scannerViewControllerDidCancel()
}

class ScannerViewController: UIViewController {
    weak var delegate: ScannerViewControllerDelegate?
    
    // Camera
    private let captureSession = AVCaptureSession()
    private let videoOutput = AVCaptureVideoDataOutput()
    private let photoOutput = AVCapturePhotoOutput()
    private var previewLayer: AVCaptureVideoPreviewLayer?
    
    // UI
    private let shutterButton = UIButton(type: .custom)
    private let closeButton = UIButton(type: .system)
    
    // Vision
    private var isProcessing = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupCamera()
        setupUI()
        startSession()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        previewLayer?.frame = view.bounds
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        captureSession.stopRunning()
    }
    
    private func setupCamera() {
        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
              let input = try? AVCaptureDeviceInput(device: device) else {
            return
        }
        
        captureSession.beginConfiguration()
        
        if captureSession.canAddInput(input) {
            captureSession.addInput(input)
        }
        
        // No video output needed for live detection anymore
        
        if captureSession.canAddOutput(photoOutput) {
            captureSession.addOutput(photoOutput)
        }
        
        captureSession.commitConfiguration()
        
        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer?.videoGravity = .resizeAspectFill
        if let previewLayer = previewLayer {
            view.layer.addSublayer(previewLayer)
        }
    }
    
    private func setupUI() {
        // Shutter Button
        shutterButton.translatesAutoresizingMaskIntoConstraints = false
        shutterButton.backgroundColor = .white
        shutterButton.layer.cornerRadius = 35
        shutterButton.layer.borderWidth = 5
        shutterButton.layer.borderColor = UIColor.lightGray.cgColor
        shutterButton.addTarget(self, action: #selector(capturePhoto), for: .touchUpInside)
        view.addSubview(shutterButton)
        
        // Close Button
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        closeButton.setTitle("Cancel", for: .normal)
        closeButton.setTitleColor(.white, for: .normal)
        closeButton.addTarget(self, action: #selector(cancel), for: .touchUpInside)
        view.addSubview(closeButton)
        
        NSLayoutConstraint.activate([
            shutterButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            shutterButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -30),
            shutterButton.widthAnchor.constraint(equalToConstant: 70),
            shutterButton.heightAnchor.constraint(equalToConstant: 70),
            
            closeButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            closeButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16)
        ])
    }
    
    private func startSession() {
        DispatchQueue.global(qos: .userInitiated).async {
            self.captureSession.startRunning()
        }
    }
    
    @objc private func capturePhoto() {
        let settings = AVCapturePhotoSettings()
        photoOutput.capturePhoto(with: settings, delegate: self)
    }
    
    @objc private func cancel() {
        delegate?.scannerViewControllerDidCancel()
    }
}

extension ScannerViewController: AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        guard let imageData = photo.fileDataRepresentation(),
              let originalImage = UIImage(data: imageData) else { return }
        
        isProcessing = true
        
        // Fix orientation to be upright
        let fixedImage = fixedOrientation(for: originalImage)
        
        // Detect rectangle int the captured image
        guard let ciImage = CIImage(image: fixedImage) else {
             // Fallback to simpler processing if CIImage creation fails
             processAndReturn(image: fixedImage)
             return
        }
        
        let handler = VNImageRequestHandler(ciImage: ciImage, options: [:])
        let request = VNDetectRectanglesRequest { [weak self] request, error in
            guard let self = self else { return }
            
            var processedImage = fixedImage
            
            if let results = request.results as? [VNRectangleObservation], let bestResult = results.first {
                // Crop and Perspective Correct
                if let corrected = self.perspectiveCorrectedImage(from: fixedImage, observation: bestResult) {
                    processedImage = corrected
                }
            }
            
            // Apply B&W Filter
            processedImage = self.applyBlackAndWhiteFilter(to: processedImage)
            
            DispatchQueue.main.async {
                self.delegate?.scannerViewControllerDidCapture(processedImage)
            }
        }
        
        request.minimumConfidence = 0.8
        request.maximumObservations = 1
        
        do {
            try handler.perform([request])
        } catch {
            // Fallback if vision fails
            print("Vision request failed: \(error)")
            let bwImage = applyBlackAndWhiteFilter(to: fixedImage)
            delegate?.scannerViewControllerDidCapture(bwImage)
        }
    }
    
    private func processAndReturn(image: UIImage) {
        let final = applyBlackAndWhiteFilter(to: image)
        delegate?.scannerViewControllerDidCapture(final)
    }
    
    private func perspectiveCorrectedImage(from image: UIImage, observation: VNRectangleObservation) -> UIImage? {
        guard let ciImage = CIImage(image: image) else { return nil }
        
        let imageSize = ciImage.extent.size
        
        // Vision coordinates are normalized (0-1), bottom-left origin.
        let topLeft = VNImagePointForNormalizedPoint(observation.topLeft, Int(imageSize.width), Int(imageSize.height))
        let topRight = VNImagePointForNormalizedPoint(observation.topRight, Int(imageSize.width), Int(imageSize.height))
        let bottomLeft = VNImagePointForNormalizedPoint(observation.bottomLeft, Int(imageSize.width), Int(imageSize.height))
        let bottomRight = VNImagePointForNormalizedPoint(observation.bottomRight, Int(imageSize.width), Int(imageSize.height))
        
        let correctedImage = ciImage.applyingFilter("CIPerspectiveCorrection", parameters: [
            "inputTopLeft": CIVector(cgPoint: topLeft),
            "inputTopRight": CIVector(cgPoint: topRight),
            "inputBottomLeft": CIVector(cgPoint: bottomLeft),
            "inputBottomRight": CIVector(cgPoint: bottomRight)
        ])
        
        let context = CIContext()
        if let cgImage = context.createCGImage(correctedImage, from: correctedImage.extent) {
            return UIImage(cgImage: cgImage)
        }
        return nil
    }
    
    private func applyBlackAndWhiteFilter(to image: UIImage) -> UIImage {
        guard let ciImage = CIImage(image: image) else { return image }
        
        // "CIPhotoEffectNoir" or "CIPhotoEffectMono"
        let filter = CIFilter(name: "CIPhotoEffectNoir")
        filter?.setValue(ciImage, forKey: kCIInputImageKey)
        
        guard let outputImage = filter?.outputImage else { return image }
        
        let context = CIContext()
        if let cgImage = context.createCGImage(outputImage, from: outputImage.extent) {
            return UIImage(cgImage: cgImage)
        }
        return image
    }
    
    private func fixedOrientation(for image: UIImage) -> UIImage {
        if image.imageOrientation == .up {
            return image
        }
        
        UIGraphicsBeginImageContextWithOptions(image.size, false, image.scale)
        image.draw(in: CGRect(origin: .zero, size: image.size))
        let normalizedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return normalizedImage ?? image
    }
}
