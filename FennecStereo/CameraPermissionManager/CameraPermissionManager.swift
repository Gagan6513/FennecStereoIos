//
//  CameraPermissionManager.swift
//  FennecStereo
//
//  Created by Hiren Nakum on 01/10/25.
//

import AVFoundation

class CameraPermissionManager {
    static func checkPermission(completion: @escaping (Bool) -> Void) {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            // Already authorized
            completion(true)
            
        case .notDetermined:
            // First time asking → request
            AVCaptureDevice.requestAccess(for: .video) { granted in
                DispatchQueue.main.async {
                    completion(granted)
                }
            }
            
        case .denied, .restricted:
            // User denied or cannot grant access
            completion(false)
            
        @unknown default:
            completion(false)
        }
    }
}
