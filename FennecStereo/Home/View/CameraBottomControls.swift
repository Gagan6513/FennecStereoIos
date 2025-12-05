//
//  CameraBottomControls.swift
//  FennecStereo
//
//  Created by Kushkumar on 08/10/25.
//

import SwiftUI
import Photos
//import SwiftUIViewRecorder
import Combine

struct CameraBottomControls: View {
    @State private var recorderVM: ViewRecordingSessionViewModel<URL>?
    @State private var session: ViewRecordingSession<URL>? = nil
    @State private var cancellables = Set<AnyCancellable>()
    @State private var renderer: MP4FramesRenderer?
    @ObservedObject var vm: HomeViewModel
    @Binding var capturedView: AnyView?
    
    @StateObject private var powerMonitor = LowPowerModeMonitor()
    
    var body: some View {
        VStack(spacing: 12) {
            
            Text((vm.firstImage != nil && vm.secondImage != nil) ? "PREVIEW" : (vm.firstImage != nil) ? "RIGHT CLICK" : "LEFT CLICK")
                .foregroundColor(.yellow)
                .font(.system(size: 14, weight: .medium))
                .padding(.top, 5)
                .shadow(radius: 4)

            HStack {
                Button(action: vm.swapImages) {
                    CameraBottomButton(icon: "arrow.left.arrow.right", title: "Swap")
                }
                Spacer()
                Button(action: vm.rotateImages) {
                    CameraBottomButton(icon: "arrow.clockwise", title: "Rotate", isHighlighted: vm.isRotate)
                }
                Spacer()
                Button(action: vm.resetImages) {
                    CameraBottomButton(icon: "trash", title: "Delete")
                }
                Spacer()
                Button(action: {
                    
                    guard (vm.firstImage != nil && vm.secondImage != nil) else {return}
               
                    if let view = capturedView {
                        
                        if vm.isWigglegramOn {
                            
                            guard !self.powerMonitor.isLowPowerModeEnabled else {
                                vm.toastMessage = "⚠️ Low Power Mode is ON. Please turn it OFF to record the video."
                                vm.showToast = true
                                AppUtils.shared.hapticEffect()
                                return
                            }
                            
                            AppUtils.shared.hapticEffect()
                            vm.isDisabledSave = true
                            
                            self.startRecording(capturedView: view)
                            DispatchQueue.main.asyncAfter(deadline: .now() + 10, execute: {
                                session?.stopRecording()
                                vm.toastMessage = "Saving video..."
                                vm.isLoaderShow = true
                            })
                        } else {
                            let image = view.snapshot(targetSize: CGSize(width: vm.previewWidth, height: vm.previewHeight))
                            
                            saveImageToGallery(image) { success in
                                DispatchQueue.main.async {
                                    vm.toastMessage = "Successfully saved."
                                    vm.showToast = true
                                    AppUtils.shared.hapticEffect()
                                }
                            }
                        }
                        
                        if vm.separatePhotos { //For Separate Photos option
                            if let firstImage = vm.firstImage, let secondImage = vm.secondImage {
                                saveImageToGallery(firstImage) { success in}
                                saveImageToGallery(secondImage) { success in}
                            }
                        }
                    }
                }) {
                    
                    VStack(spacing: 0) {
                        Image("ic_download")
                            .resizable()
                            .frame(width: 20, height: 20)
                            .foregroundColor(.white)
                        Text("Save")
                            .font(.system(size: 12, weight: .light))
                            .foregroundColor(.white)
                    }
                    .opacity(vm.isDisabledSave ? 0.5 : 1)
                }
                //.disabled(vm.isDisabledSave)
            }
            .padding(.horizontal, 24)

            HStack {
                CameraBottomButton(icon: "photo.on.rectangle", title: "Select")
                    .onTapGesture {
                        if vm.imageCaptureIndex < 2 {
                            vm.showPhotoPicker = true
                        }
                    }
                Spacer()
                ZStack {
                    Circle().stroke(Color.white, lineWidth: 4).frame(width: 60, height: 60)
                    Circle().fill(Color.white).frame(width: 35, height: 35)
                }
                .onTapGesture {
                    if vm.imageCaptureIndex < 2 {
                        vm.cameraManager.capturePhoto(isFlashOn: vm.isFlashOn, shutterSound: vm.shutterSound)
                        DispatchQueue.main.async {
                            AppUtils.shared.hapticEffect()
                        }
                    }
                }
                Spacer()
                Button(action: vm.switchCamera) {
                    CameraBottomButton(icon: "arrow.2.circlepath", title: "Switch")
                }
            }
            .padding(.horizontal, 24)
        }
        
        
    }
    
    func saveImageToGallery(_ image: UIImage, completion: @escaping (Bool) -> Void) {
        PHPhotoLibrary.requestAuthorization { status in
            guard status == .authorized else {
                completion(false)
                return
            }
            UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
            completion(true)
        }
    }
    
    
    private func startRecording(capturedView: AnyView) {
        
        do {
            self.renderer = MP4FramesRenderer(
                outputURL: FileManager.default.temporaryDirectory.appendingPathComponent("demo-\(UUID().uuidString).mp4"), videoSize: CGSize(width: vm.previewWidth, height: vm.previewHeight)
            )
            
            guard let renderer = renderer else {return}
            
            let newSession = try ViewRecordingSession(
                view: capturedView,
                framesRenderer: renderer,
                useSnapshots: false,
                duration: 10,
                framesPerSecond: 10
            )
            
            recorderVM = ViewRecordingSessionViewModel<URL>()
            
            recorderVM?.handleRecording(session: newSession)
            
            // ✅ Automatically save when asset (URL) is ready
            recorderVM?.$asset
                .compactMap { $0 }
                .sink { videoURL in
                    saveToPhotos(videoURL)
                }
                .store(in: &cancellables)
            
            session = newSession
            
        } catch {
            print("❌ Recording failed: \(error.localizedDescription)")
        }
    }
    
    // ✅ Save video to Photos Library
    private func saveToPhotos(_ url: URL) {
        PHPhotoLibrary.requestAuthorization { status in
            guard status == .authorized else {
                print("❌ Photos permission denied")
                DispatchQueue.main.async {
                    vm.isDisabledSave = false
                    vm.isLoaderShow = false
                }
                return
            }
            
                PHPhotoLibrary.shared().performChanges({
                    PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: url)
                }) { success, error in
                    DispatchQueue.main.async {
                        
                        vm.isLoaderShow = false
                        
                        if success {
                            print("✅ Saved to Photos!")
                            try? FileManager.default.removeItem(at: url)
                            
                            vm.toastMessage = "Successfully saved."
                            vm.showToast = true
                            AppUtils.shared.hapticEffect()
                        } else {
                            print("❌ Error saving: \(error?.localizedDescription ?? "")")
                        }
                        
                        self.session = nil
                        self.recorderVM?.asset = nil
                        self.cancellables.removeAll()
                        self.renderer = nil
                        self.recorderVM = nil
                        vm.isDisabledSave = false
                    }
                }
        }
    }
}

