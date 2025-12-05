//
//  CameraContentView.swift
//  FennecStereo
//
//  Created by Kushkumar on 08/10/25.
//
import SwiftUI

struct CameraContentView: View {
    @ObservedObject var vm: HomeViewModel
    @State private var capturedView: AnyView?
    
    var body: some View {
        VStack(spacing: 8) {
            CameraTopControls(vm: vm)
            CameraPreviewSection(vm: vm, capturedView: $capturedView)
                .frame(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.width * 1.33)
                .gesture(
                    MagnificationGesture()
                        .onChanged { value in
                            vm.pinchScale = value
                            vm.applyPinchZoom()
                        }
                        .onEnded { _ in
                            // Reset to avoid jumps
                            vm.lastPinchValue = 1.0
                            vm.pinchScale = 1.0
                        }
                )
            CameraBottomControls(vm: vm, capturedView: $capturedView)
            Spacer()
        }
    }
    
}
