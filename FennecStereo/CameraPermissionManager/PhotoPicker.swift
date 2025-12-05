//
//  PhotoPicker.swift
//  FennecStereo
//
//  Created by Hiren Nakum on 01/10/25.
//

import Foundation
import SwiftUI
import PhotosUI

struct PhotoPicker: UIViewControllerRepresentable {
    @Binding var selectedImages: [UIImage]   // <-- changed to array
    @Environment(\.dismiss) var dismiss

    func makeUIViewController(context: Context) -> PHPickerViewController {
        var config = PHPickerConfiguration()
        config.filter = .images
        config.selectionLimit = 2   // <-- allow 2 images

        let picker = PHPickerViewController(configuration: config)
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let parent: PhotoPicker

        init(_ parent: PhotoPicker) {
            self.parent = parent
        }

        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {

            let group = DispatchGroup()
            var loadedImages: [UIImage] = []

            for result in results {
                let provider = result.itemProvider
                if provider.canLoadObject(ofClass: UIImage.self) {
                    group.enter()
                    provider.loadObject(ofClass: UIImage.self) { image, error in
                        if let img = image as? UIImage {
                            loadedImages.append(img)
                        }
                        group.leave()
                    }
                }
            }

            group.notify(queue: .main) {
                self.parent.selectedImages = loadedImages   // set final array
                self.parent.dismiss()
            }
        }
    }
}
