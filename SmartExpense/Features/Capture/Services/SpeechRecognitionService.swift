//
//  SpeechRecognitionService.swift
//  SmartExpense
//
//  Created by Henry Wang on 2025-11-29.
//

import Speech
import AVFoundation
import Combine

class SpeechRecognitionService: ObservableObject {
    @Published var transcription = ""
    @Published var isRecording = false
    @Published var error: String?
    
    private var audioEngine: AVAudioEngine?
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
    
    func startRecording() async throws {
        // Check permissions
        let micPermission = await PermissionsManager.shared.requestMicrophonePermission()
        guard micPermission else {
            throw SpeechError.microphonePermissionDenied
        }
        
        let speechPermission = await PermissionsManager.shared.requestSpeechRecognitionPermission()
        guard speechPermission else {
            throw SpeechError.speechRecognitionPermissionDenied
        }
        
        // Cancel any ongoing task
        recognitionTask?.cancel()
        recognitionTask = nil
        
        // Configure audio session
        let audioSession = AVAudioSession.sharedInstance()
        try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
        try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        
        // Create recognition request
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let recognitionRequest = recognitionRequest else {
            throw SpeechError.recognitionRequestFailed
        }
        
        recognitionRequest.shouldReportPartialResults = true
        
        // Create audio engine
        audioEngine = AVAudioEngine()
        guard let audioEngine = audioEngine else {
            throw SpeechError.audioEngineFailed
        }
        
        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
            recognitionRequest.append(buffer)
        }
        
        audioEngine.prepare()
        try audioEngine.start()
        
        // Start recognition
        await MainActor.run {
            isRecording = true
            transcription = ""
        }
        
        recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest) { [weak self] result, error in
            guard let self = self else { return }
            
            if let result = result {
                Task { @MainActor in
                    self.transcription = result.bestTranscription.formattedString
                }
            }
            
            if error != nil || result?.isFinal == true {
                Task {
                    await self.stopRecording()
                }
            }
        }
    }
    
    func stopRecording() async {
        audioEngine?.stop()
        audioEngine?.inputNode.removeTap(onBus: 0)
        
        recognitionRequest?.endAudio()
        recognitionRequest = nil
        
        recognitionTask?.cancel()
        recognitionTask = nil
        
        await MainActor.run {
            isRecording = false
        }
    }
}

enum SpeechError: LocalizedError {
    case microphonePermissionDenied
    case speechRecognitionPermissionDenied
    case recognitionRequestFailed
    case audioEngineFailed
    
    var errorDescription: String? {
        switch self {
        case .microphonePermissionDenied:
            return "Microphone permission is required for voice input"
        case .speechRecognitionPermissionDenied:
            return "Speech recognition permission is required"
        case .recognitionRequestFailed:
            return "Failed to create recognition request"
        case .audioEngineFailed:
            return "Failed to initialize audio engine"
        }
    }
}
