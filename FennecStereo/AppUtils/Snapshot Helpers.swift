//
//  Snapshot Helpers.swift
//  FennecStereo
//
//  Created by Kushkumar on 14/10/25.
//

import SwiftUI
import UIKit
import Photos

/// Renders a SwiftUI `View` into a UIImage with the given size.
/// Returns nil on failure.
func snapshot<Content: View>(of view: Content, size: CGSize, scale: CGFloat = UIScreen.main.scale) -> UIImage? {
    // Make hosting controller
    let hosting = UIHostingController(rootView: view)
    let targetSize = CGSize(width: max(1, size.width), height: max(1, size.height))

    // IMPORTANT: set the correct size on the view and layout
    hosting.view.bounds = CGRect(origin: .zero, size: targetSize)
    hosting.view.backgroundColor = .clear
    hosting.view.setNeedsLayout()
    hosting.view.layoutIfNeeded()

    // Render using UIGraphicsImageRenderer
    let format = UIGraphicsImageRendererFormat()
    format.scale = scale
    let renderer = UIGraphicsImageRenderer(size: targetSize, format: format)

    let image = renderer.image { context in
        // drawHierarchy is best for complex SwiftUI content
        hosting.view.drawHierarchy(in: hosting.view.bounds, afterScreenUpdates: true)
    }

    return image
}

/// Save UIImage to photo library (requests permission if needed)
func saveImageToGallery(_ image: UIImage, completion: @escaping (Bool, Error?) -> Void) {
    let saveHandler: () -> Void = {
        PHPhotoLibrary.shared().performChanges({
            PHAssetChangeRequest.creationRequestForAsset(from: image)
        }, completionHandler: { success, error in
            DispatchQueue.main.async {
                completion(success, error)
            }
        })
    }

    // Request add-only authorization if available (iOS 14+), otherwise fallback.
    if #available(iOS 14, *) {
        PHPhotoLibrary.requestAuthorization(for: .addOnly) { status in
            DispatchQueue.main.async {
                if status == .authorized || status == .limited {
                    saveHandler()
                } else {
                    completion(false, NSError(domain: "PhotoAuth", code: 1, userInfo: [NSLocalizedDescriptionKey: "Photo permission denied"]))
                }
            }
        }
    } else {
        PHPhotoLibrary.requestAuthorization { status in
            DispatchQueue.main.async {
                if status == .authorized {
                    saveHandler()
                } else {
                    completion(false, NSError(domain: "PhotoAuth", code: 1, userInfo: [NSLocalizedDescriptionKey: "Photo permission denied"]))
                }
            }
        }
    }
}
