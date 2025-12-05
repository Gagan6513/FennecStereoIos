//
//  DeviceLevelManager.swift
//  FennecStereo
//
//  Created by Kushkumar on 15/10/25.
//

import SwiftUI
import CoreMotion

// MARK: - Device Level Manager (No Change)

class DeviceLevelManager: ObservableObject {
    private let motion = CMMotionManager()
    @Published var roll: Double = 0.0
    @Published var pitch: Double = 0.0
    @Published var isLevel: Bool = false

    init() {
        motion.deviceMotionUpdateInterval = 0.1
        // Ensure motion updates are available
        guard motion.isDeviceMotionAvailable else {
            print("Device Motion is not available on this device.")
            return
        }

        motion.startDeviceMotionUpdates(to: .main) { motionData, _ in
            guard let data = motionData else { return }
            
            // Roll: Rotation around the axis pointing out of the screen (side-to-side tilt)
            self.roll = data.attitude.roll * 180 / .pi       // Convert to degrees
            
            // Pitch: Rotation around the side-to-side axis (front-to-back tilt)
            self.pitch = data.attitude.pitch * 180 / .pi     // Convert to degrees

            // Consider device level if both angles are close to zero (within 2 degrees)
            self.isLevel = abs(self.roll) < 2.0 //&& abs(self.pitch) < 2.0
        }
    }

    deinit {
        motion.stopDeviceMotionUpdates()
    }
}
