//
//  CameraPreviewSection.swift
//  FennecStereo
//
//  Created by Kushkumar on 08/10/25.
//

import SwiftUI

struct CameraPreviewSection: View {
    @ObservedObject var vm: HomeViewModel
    @State private var videoURL: URL? = nil
    @Binding var capturedView: AnyView?
    @StateObject private var levelManager = DeviceLevelManager()
    @State private var focusPoint: CGPoint? = nil
    
    
    var body: some View {
        GeometryReader { geometry in
            
            ZStack(alignment:.center) {
                if let firstImage = vm.firstImage, let secondImage = vm.secondImage {
                   
                    if vm.isCropOn {
                        
                        CropView(vm: vm)
                        
                    } else {
                        
                        // This creates the view based on the current mode, WITHOUT the zoom/pan transforms.
                        let baseView: some View = {
                            if vm.isWigglegramOn {
                                return AnyView(WigglegramView(firstImage: firstImage, secondImage: secondImage, animationSpeed: 0.1)).rotationEffect(vm.isRotate ? .degrees(90) : .degrees(0))
                                    
                            } else if vm.isSBSOn {
                                return AnyView(SBSView(firstImage: firstImage, secondImage: secondImage, offset: 1)).rotationEffect(vm.isRotate ? .degrees(90) : .degrees(0))
                            } else {
                                return AnyView(AnaglyphView(firstImage: firstImage, secondImage: secondImage, vm: vm)).rotationEffect(vm.isRotate ? .degrees(90) : .degrees(0))
                            }
                        }()
                        
                        // 1. The live, interactive content (with zoom/pan gestures)
                        let interactiveContent = ZoomableView(accumulatedScale: $vm.previewScale,accumulatedOffset: $vm.previewOffset) {
                            baseView // Use the computed view variable
                                
                        }
                            .clipped()
                        
                        let captureBackgroundColor = vm.border ?
                        Border.color(border: Border(rawValue: vm.selectedBorderColor)!) :
                        Color.black.opacity(0.9)
                        
                        // 2. The static content for capture (applies the FINAL transforms)
                        let staticContent = baseView
                            .frame(width: geometry.size.width, height: geometry.size.height)
                            .scaleEffect(vm.previewScale)
                            .offset(vm.previewOffset)
                            .background(captureBackgroundColor)
                            .clipped()
                        
                        // ... rest of the logic ...
                        interactiveContent
                            .onAppear { capturedView = AnyView(staticContent) }
                            .onChange(of: vm.isWigglegramOn) { capturedView = AnyView(staticContent) }
                            .onChange(of: vm.isSBSOn) { capturedView = AnyView(staticContent) }
                            .onChange(of: vm.isAnaglyphOn) { capturedView = AnyView(staticContent) }
                            .onChange(of: vm.previewScale) { capturedView = AnyView(staticContent) }
                            .onChange(of: vm.previewOffset) { capturedView = AnyView(staticContent) }
                            .onChange(of: vm.isRotate) { capturedView = AnyView(staticContent) }
                    }
                    
                } else {
                    
                    if vm.hasCameraPermission {
                        CameraPreview(session: vm.cameraManager.session)
                        .ignoresSafeArea()
                        .onTapGesture(count: 2) {
                            vm.switchCamera()
                        }
                    } else {
                        DeniedCameraView()
                    }
                }
                
                if  vm.hasCameraPermission && (vm.firstImage == nil || vm.secondImage == nil) {
                    VStack {
                        Spacer()
                        CustomSlider(value: $vm.sliderValue)
                            .frame(height: 40)
                            .onChange(of: vm.sliderValue) { _, _ in vm.updateZoom() }
                    }
                    .padding(.horizontal, UIScreen.main.bounds.width / 4)
                    .padding(.bottom, 8)
                }
                
                if vm.hasCameraPermission && vm.grid && (vm.firstImage == nil || vm.secondImage == nil) {
                    GridLines()
                }
                
                if vm.hasCameraPermission && vm.level && (vm.firstImage == nil || vm.secondImage == nil) {
                    VisualLevelIndicator(roll: levelManager.roll, isLevel: levelManager.isLevel)
                }
                
                if let focusPoint = focusPoint, (vm.firstImage == nil || vm.secondImage == nil) {
                    
                    Image("ic_focus").renderingMode(.template)
                        .resizable()
                        .frame(width: 50, height: 50)
                        .foregroundColor(.yellow)
                        .position(focusPoint)
                        .animation(.easeOut, value: focusPoint)
                }
                
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
            .background(vm.border ? Border.color(border: Border(rawValue: vm.selectedBorderColor)!) : Border.color(border: .backGround))
            .onAppear {
                vm.previewWidth = geometry.size.width
                vm.previewHeight = geometry.size.height
                
                vm.cameraManager.startVolumeButtonCapture {
                    if vm.hasCameraPermission && (vm.firstImage == nil || vm.secondImage == nil) {
                        vm.cameraManager.capturePhoto(isFlashOn: vm.isFlashOn, shutterSound: vm.shutterSound)
                        AppUtils.shared.hapticEffect()
                    }
                    
                }
            }
            .onDisappear {
                vm.cameraManager.stopVolumeButtonCapture()
            }
            .onTapGesture { location in
                focusPoint = location
                vm.cameraManager.focus(at: location, in: geometry.size)
                // Remove rectangle after 0.5s
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    focusPoint = nil
                }
            }
            
        }
    }
    
    
}

struct GridLines: View {
    var body: some View {
        ZStack(alignment: .center) {
            VStack(spacing: 0) {
                Spacer()
                Divider()
                    .background(Color.white.opacity(0.7))
                Spacer()
                Divider()
                    .background(Color.white.opacity(0.7))
                Spacer()
            }
            HStack(spacing: 0) {
                Spacer()
                Divider()
                    .background(Color.white.opacity(0.7))
                Spacer()
                Divider()
                    .background(Color.white.opacity(0.7))
                Spacer()
            }
        }
    }
}

struct VisualLevelIndicator: View {
    let roll: Double
    let isLevel: Bool
    
    // The angle in degrees for rotation. We negate the roll so the line visually follows the device tilt.
    private var rotationAngle: Angle {
        Angle(degrees: -roll)
    }
    
    private var indicatorColor: Color {
        isLevel ? Color.yellow : Color.white
    }
    
    var body: some View {
        // Use a black background to emphasize the lines
        ZStack {
            
            Rectangle()
                .frame(width: 80, height: 1.5)
                .foregroundColor(.white)
                .opacity(0.5)

            Rectangle()
                .frame(width: 80, height: 1.5)
                .foregroundColor(indicatorColor)
                .rotationEffect(rotationAngle)
                .animation(.linear(duration: 1), value: roll)
        }
    }
}

