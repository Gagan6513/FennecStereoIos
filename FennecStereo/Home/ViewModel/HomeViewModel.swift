//
//  HomeViewModel.swift
//  FennecStereo
//
//  Created by Kushkumar on 08/10/25.
//

import SwiftUI
import Combine

@MainActor
final class HomeViewModel: ObservableObject {
    
    // MARK: - Dependencies
    @Published var cameraManager = CameraManager()
    
    // MARK: - Published
    @Published var sliderValue: CGFloat = 0.0
    @Published var hasCameraPermission = false
    @Published var isAnaglyphOn = true
    @Published var isSBSOn = false
    @Published var isFlashOn = false
    @Published var isCropOn = false
    @Published var isWigglegramOn = false
    @Published var selectedImage: [UIImage] = []
    @Published var firstImage: UIImage? = nil
    @Published var secondImage: UIImage? = nil
    @Published var originalFirstImage: UIImage? = nil
    @Published var originalSecondImage: UIImage? = nil
    @Published var imageCaptureIndex: Int = 0
    @Published var isRotate = false
    @Published var showPhotoPicker = false

    @Published var separatePhotos = false
    @Published var shutterSound = false
    @Published var level = false
    @Published var border = true
    @Published var fuseDotGuide = false
    @Published var grid = false
    @Published var selectedBorderColor: String = Border.white.rawValue
    @Published var gifURL: URL? = nil
    
    @Published var anaglyphImage: UIImage? = nil
    @Published var previewScale: CGFloat = 1.0
    @Published var previewOffset: CGSize = .zero
    @Published var previewWidth: CGFloat = 1.0
    @Published var previewHeight: CGFloat = 1.0
    @Published var showToast: Bool = false
    @Published var isDisabledSave: Bool = false
    @Published var cropPress: Bool = false
    @Published var isLoaderShow: Bool = false
    
    private var cancellables = Set<AnyCancellable>()
    
    @Published var hasCameraPermissionCheck = false
    @Published var pinchScale: CGFloat = 1.0
    @Published var lastPinchValue: CGFloat = 1.0
    
    @Published var toastMessage = "Start Recording..."
    
    let borderOptions: [String] = [
        Border.offBlack.rawValue,
        Border.black.rawValue,
        Border.white.rawValue,
        Border.offWhite.rawValue
    ]
    
    init(){
        self.initialSetup()
        observeCameraManager()
   }
    
    private func observeCameraManager() {
        cameraManager.$capturedImage
            .receive(on: DispatchQueue.main)
            .sink { [weak self] image in
                guard let self = self else { return }
               // self.latestCapturedImage = image
                self.handleCapturedImage(image)
            }
            .store(in: &cancellables)
    }

   
   func initialSetup() {
       
       print("fsdfsdfdsfdsf")
       
       if let separatePhotos = UserDefaults.standard.separatePhotos {
           self.separatePhotos = separatePhotos
       }
       
       if let shutterSound = UserDefaults.standard.shutterSound {
           self.shutterSound = shutterSound
       }
       
       if let level = UserDefaults.standard.level {
           self.level = level
       }
       
       if let border = UserDefaults.standard.border {
           self.border = border
       }
       
       if let borderName = UserDefaults.standard.borderName {
           self.selectedBorderColor = borderName
       }
       
       if let fuseDotGuide = UserDefaults.standard.fuseDotGuide {
           self.fuseDotGuide = fuseDotGuide
       }
       
       if let grid = UserDefaults.standard.grid {
           self.grid = grid
       }
       
       if let rotate = UserDefaults.standard.rotate {
           self.isRotate = rotate
       }
       
       if let flash = UserDefaults.standard.flash {
           self.isFlashOn = flash
       }
   }

    // MARK: - Lifecycle
    func onAppear() {
        CameraPermissionManager.checkPermission { granted in
            DispatchQueue.main.async {
                
                
                self.hasCameraPermission = granted
                
                self.hasCameraPermissionCheck = true
            }
        }
    }

    func startCameraIfNeeded() {
        if hasCameraPermission { cameraManager.startSession() }
    }

    func stopCamera() { cameraManager.stopSession() }

    // MARK: - Toggles
    func toggleFlash() {
        if self.imageCaptureIndex < 2 {
            AppUtils.shared.hapticEffect()
            isFlashOn.toggle()
        }
    }
    
    func toggleCrop() {
        
        guard self.firstImage != nil && self.secondImage != nil else {return}
        
        AppUtils.shared.hapticEffect()
        
        if !isCropOn {
            isCropOn = true
        } else {
            cropPress = true
        }
    }

    func toggleAnaglyph() {
        //guard self.firstImage != nil && self.secondImage != nil else {return}
        
        AppUtils.shared.hapticEffect()
        isSBSOn = false
        isWigglegramOn = false
        isAnaglyphOn = true
    }
    
    func toggleSBS() {
        //guard self.firstImage != nil && self.secondImage != nil else {return}
        
        AppUtils.shared.hapticEffect()
        isAnaglyphOn = false
        isWigglegramOn = false
        isSBSOn = true
    }

    func toggleWigglegram() {
        //guard self.firstImage != nil && self.secondImage != nil && !isWigglegramOn  else {return}
        AppUtils.shared.hapticEffect()
        isWigglegramOn = true
    }

    func rotateImages() {
        guard self.firstImage != nil && self.secondImage != nil else {return}
        AppUtils.shared.hapticEffect()
        isRotate.toggle()
    }

    func resetImages() {
        AppUtils.shared.hapticEffect()
        isCropOn = false
        firstImage = nil
        secondImage = nil
        originalFirstImage = nil
        originalSecondImage = nil
        imageCaptureIndex = 0
        previewScale = 1.0
        previewOffset = .zero
        pinchScale = 1.0
        lastPinchValue = 1.0
        sliderValue = 0.0
        updateZoom()
    }

    func swapImages() {
        guard self.firstImage != nil && self.secondImage != nil else {return}
        AppUtils.shared.hapticEffect()
        let temp = firstImage
        firstImage = secondImage
        secondImage = temp
        
        let temp2 = originalFirstImage
        originalFirstImage = originalSecondImage
        originalSecondImage = temp2
    }

    func handleCapturedImage(_ image: UIImage?) {
        guard let image = image else { return }
        
        if self.firstImage == nil {
            self.firstImage = image
            self.originalFirstImage = image
            self.imageCaptureIndex = 1
        } else if secondImage == nil {
            self.secondImage = image
            self.originalSecondImage = image
            self.imageCaptureIndex = 2
        }
        print("imageCaptureIndex ", imageCaptureIndex)
    }

    func switchCamera() {
        if self.imageCaptureIndex < 2 {
            AppUtils.shared.hapticEffect()
            sliderValue = 0.0
            cameraManager.switchCamera()
        }
    }

    func updateZoom() {
        let zoomFactor = 1.0 + (sliderValue * 4.0)
        cameraManager.setZoom(factor: zoomFactor)
    }
    
    // MARK: - Actions
    func openInstagram() {
        AppUtils.shared.hapticEffect()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            AppUtils.openURL(AppConstant.instagramUrl)
        }
    }
    
    func openYouTube() {
        AppUtils.shared.hapticEffect()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            AppUtils.openURL(AppConstant.youtubeUrl)
        }
    }
    
    func openWebsite() {
        AppUtils.shared.hapticEffect()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            AppUtils.openURL("https://fennecstereo.com/")
        }
    }
    
    func applyPinchZoom() {
        // Convert pinch delta into smooth zoom delta
        let delta = pinchScale / lastPinchValue
        lastPinchValue = pinchScale
        let currentZoomFactor = 1.0 + (sliderValue * 4.0)
        let newZoomFactor = currentZoomFactor * delta
        let newSliderValue = (newZoomFactor - 1.0) / 4.0
        sliderValue = max(0.0, min(1.0, newSliderValue))
        updateZoom()
    }

}




