//
//  PermissionsManager.swift
//  SmartExpense
//
//  Created by Henry Wang on 2025-11-29.
//

import AVFoundation
import Photos
import Speech

enum PermissionType {
    case camera
    case photoLibrary
    case microphone
}

enum PermissionStatus {
    case authorized
    case denied
    case notDetermined
}

class PermissionsManager {
    static let shared = PermissionsManager()
    
    private init() {}
    
    // MARK: - Camera Permission
    
    func checkCameraPermission() -> PermissionStatus {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            return .authorized
        case .denied, .restricted:
            return .denied
        case .notDetermined:
            return .notDetermined
        @unknown default:
            return .denied
        }
    }
    
    func requestCameraPermission() async -> Bool {
        await AVCaptureDevice.requestAccess(for: .video)
    }
    
    // MARK: - Photo Library Permission
    
    func checkPhotoLibraryPermission() -> PermissionStatus {
        let status = PHPhotoLibrary.authorizationStatus(for: .readWrite)
        switch status {
        case .authorized, .limited:
            return .authorized
        case .denied, .restricted:
            return .denied
        case .notDetermined:
            return .notDetermined
        @unknown default:
            return .denied
        }
    }
    
    func requestPhotoLibraryPermission() async -> Bool {
        let status = await PHPhotoLibrary.requestAuthorization(for: .readWrite)
        return status == .authorized || status == .limited
    }
    
    // MARK: - Microphone Permission
    
    func checkMicrophonePermission() -> PermissionStatus {
        switch AVAudioSession.sharedInstance().recordPermission {
        case .granted:
            return .authorized
        case .denied:
            return .denied
        case .undetermined:
            return .notDetermined
        @unknown default:
            return .denied
        }
    }
    
    func requestMicrophonePermission() async -> Bool {
        await withCheckedContinuation { continuation in
            AVAudioSession.sharedInstance().requestRecordPermission { granted in
                continuation.resume(returning: granted)
            }
        }
    }
    
    // MARK: - Speech Recognition Permission
    
    func checkSpeechRecognitionPermission() -> PermissionStatus {
        switch SFSpeechRecognizer.authorizationStatus() {
        case .authorized:
            return .authorized
        case .denied, .restricted:
            return .denied
        case .notDetermined:
            return .notDetermined
        @unknown default:
            return .denied
        }
    }
    
    func requestSpeechRecognitionPermission() async -> Bool {
        await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { status in
                continuation.resume(returning: status == .authorized)
            }
        }
    }
    
    // MARK: - Helper Methods
    
    func getPermissionMessage(for type: PermissionType) -> String {
        switch type {
        case .camera:
            return "Camera access is required to scan receipts. Please enable it in Settings."
        case .photoLibrary:
            return "Photo library access is required to select receipt images. Please enable it in Settings."
        case .microphone:
            return "Microphone access is required for voice expenses. Please enable it in Settings."
        }
    }
}
