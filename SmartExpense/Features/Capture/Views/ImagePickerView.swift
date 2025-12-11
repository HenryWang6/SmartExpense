//
//  ImagePickerView.swift
//  SmartExpense
//
//  Created by Henry Wang on 2025-11-29.
//

import SwiftUI
import UIKit

struct ImagePickerView: UIViewControllerRepresentable {
    @Environment(\.dismiss) private var dismiss
    
    let sourceType: UIImagePickerController.SourceType
    let onImageSelected: (UIImage) -> Void
    var onCancel: (() -> Void)? = nil
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = sourceType
        picker.delegate = context.coordinator
        picker.allowsEditing = false
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: ImagePickerView
        
        init(_ parent: ImagePickerView) {
            self.parent = parent
        }
        
        func imagePickerController(
            _ picker: UIImagePickerController,
            didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]
        ) {
            if let image = info[.originalImage] as? UIImage {
                parent.onImageSelected(image)
            }
            parent.dismiss()
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            if let onCancel = parent.onCancel {
                onCancel()
            } else {
                parent.dismiss()
            }
        }
    }
}
