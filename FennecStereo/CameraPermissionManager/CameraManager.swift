//
//  CameraManager.swift
//  FennecStereo
//
//  Created by Hiren Nakum on 01/10/25.
//

import AVFoundation
import SwiftUI
import Combine
import MediaPlayer

class CameraManager: NSObject, ObservableObject, AVCapturePhotoCaptureDelegate {
    @Published var isRunning: Bool = false
    
    let session = AVCaptureSession()
    private var currentInput: AVCaptureDeviceInput?
    private let output = AVCapturePhotoOutput()
    
    private var volumeView: MPVolumeView?
    private var volumeObservation: NSKeyValueObservation?
    private var lastVolume: Float = AVAudioSession.sharedInstance().outputVolume
    
    
    //    private let photoOutput = AVCapturePhotoOutput()
    
    @Published var capturedImage: UIImage?
    
    override init() {
        super.init()
        configureSession(position: .back)
    }
    
    private func configureSession(position: AVCaptureDevice.Position) {
        session.beginConfiguration()
        session.sessionPreset = .photo
        
        // Remove existing inputs
        if let currentInput = currentInput {
            session.removeInput(currentInput)
        }
        
        // Add new camera input
        if let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: position),
           let input = try? AVCaptureDeviceInput(device: device),
           session.canAddInput(input) {
            session.addInput(input)
            self.currentInput = input
        }
        
        // Add photo output (only once)
        if session.outputs.isEmpty, session.canAddOutput(output) {
            session.addOutput(output)
        }
        
        session.commitConfiguration()
    }
    
    func startSession() {
        if !session.isRunning {
            DispatchQueue.global(qos: .userInitiated).async {
                self.session.startRunning()
                DispatchQueue.main.async {
                    self.isRunning = true
                }
            }
        }
    }
    
    func stopSession() {
        if session.isRunning {
            DispatchQueue.global(qos: .userInitiated).async {
                self.session.stopRunning()
                DispatchQueue.main.async {
                    self.isRunning = false
                }
            }
        }
    }
    
    func toggleFlash(isOn: Bool) {
        guard let device = currentInput?.device, device.hasTorch else { return }
        
        do {
            try device.lockForConfiguration()
            if isOn {
                try device.setTorchModeOn(level: 1.0) // full brightness
            } else {
                device.torchMode = .off
            }
            device.unlockForConfiguration()
        } catch {
            print("⚠️ Torch could not be used: \(error.localizedDescription)")
        }
    }
    
    // 🚀 Switch between front and back cameras
    func switchCamera() {
        guard let currentInput = currentInput else { return }
        
        let newPosition: AVCaptureDevice.Position = currentInput.device.position == .back ? .front : .back
        configureSession(position: newPosition)
    }
    
    func setZoom(factor: CGFloat) {
        guard let device = currentInput?.device else { return }
        
        do {
            try device.lockForConfiguration()
            let zoom = max(1.0, min(factor, device.activeFormat.videoMaxZoomFactor))
            device.videoZoomFactor = zoom
            device.unlockForConfiguration()
        } catch {
            print("Failed to set zoom: \(error.localizedDescription)")
        }
    }
    
    func capturePhoto(isFlashOn: Bool, shutterSound: Bool) {
        
        if shutterSound {
            // Restore normal audio behavior
            try? AVAudioSession.sharedInstance().setActive(false)
            try? AVAudioSession.sharedInstance().setCategory(.ambient)
            try? AVAudioSession.sharedInstance().setActive(true)
        } else {
            // Make shutter silent
            try? AVAudioSession.sharedInstance().setCategory(.playAndRecord,
                                                             mode: .default,
                                                             options: [.mixWithOthers])
            try? AVAudioSession.sharedInstance().setActive(true)
        }
        
        let settings = AVCapturePhotoSettings()
        settings.flashMode = isFlashOn ? .on : .off
        output.capturePhoto(with: settings, delegate: self)
    }
    
    func photoOutput(_ output: AVCapturePhotoOutput,
                     didFinishProcessingPhoto photo: AVCapturePhoto,
                     error: Error?) {
        guard let data = photo.fileDataRepresentation(),
              var image = UIImage(data: data) else {
            return
        }
        
        // ✅ Fix mirror effect for front camera
        if currentInput?.device.position == .front {
            image = UIImage(cgImage: image.cgImage!, scale: image.scale, orientation: .leftMirrored)
        }
        
        DispatchQueue.main.async {
            self.capturedImage = image
        }
    }
    
    func focus(at point: CGPoint, in previewSize: CGSize) {
        guard let device = currentInput?.device else { return }
        do {
            try device.lockForConfiguration()
            // Convert SwiftUI tap coordinates to AVCapture coordinates (0-1)
            // Note: X and Y are swapped because camera coordinates are landscape
            let focusPoint = CGPoint(x: point.y / previewSize.height, y: 1.0 - point.x / previewSize.width)
            if device.isFocusPointOfInterestSupported {
                device.focusPointOfInterest = focusPoint
                device.focusMode = .autoFocus
            }
            if device.isExposurePointOfInterestSupported {
                device.exposurePointOfInterest = focusPoint
                device.exposureMode = .autoExpose
            }
            device.unlockForConfiguration()
        } catch {
            print("Failed to focus: \(error.localizedDescription)")
        }
    }
    
    func startVolumeButtonCapture(onTrigger: @escaping () -> Void) {
        
        // 1. Create hidden MPVolumeView
        let volumeView = MPVolumeView(frame: .zero)
        volumeView.alpha = 0.01   // Invisible, but MUST be in view hierarchy
        UIApplication.shared.windows.first?.addSubview(volumeView)
        self.volumeView = volumeView
        
        // 2. Configure audio session
        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(.ambient, options: [.mixWithOthers])
        try? session.setActive(true)
        
        // 3. Store initial volume
        lastVolume = session.outputVolume
        
        // 4. Observe volume change
        volumeObservation = session.observe(\.outputVolume, options: [.new]) { [weak self] session, change in
            guard let self = self else { return }
            
            guard let newValue = change.newValue else { return }
            
            if newValue != self.lastVolume {
                // Trigger
                onTrigger()
                
                // IMPORTANT:
                // Restore system volume immediately → prevents HUD showing
                self.setSystemVolume(self.lastVolume)
            }
        }
    }
    
    func stopVolumeButtonCapture() {
        volumeObservation?.invalidate()
        volumeObservation = nil
        volumeView?.removeFromSuperview()
        volumeView = nil
    }
    
    /// Set volume without showing HUD
    private func setSystemVolume(_ value: Float) {
        DispatchQueue.main.async {
            for view in self.volumeView?.subviews ?? [] {
                if let slider = view as? UISlider {
                    slider.value = value
                    return
                }
            }
        }
    }
}

