//
//  HomeView.swift
//  FennecStereo
//
//  Created by Hiren Nakum on 01/10/25.
//

import SwiftUI
import UIKit
import Photos

struct HomeView: View {
    @StateObject private var vm = HomeViewModel()
    @StateObject private var toastManager = ToastManager()

    var body: some View {
        NavigationStack {
            ZStack {
                Border.color(border: .backGround).ignoresSafeArea()
                if vm.hasCameraPermissionCheck {
                    CameraContentView(vm: vm)
                        .onAppear { vm.startCameraIfNeeded() }
                        .onDisappear { vm.stopCamera() }
                }
                
                if vm.isLoaderShow {
                    LoaderToastView(message: $vm.toastMessage)
                }
            }
            .disabled(vm.isDisabledSave)
            .navigationBarHidden(true)
            .onAppear { vm.onAppear() }
            .sheet(isPresented: $vm.showPhotoPicker) {
                PhotoPicker(selectedImages: $vm.selectedImage)
            }
            .onChange(of: vm.showToast, { oldValue, newValue in
                if newValue {
                    toastManager.show(message: vm.toastMessage, position: .bottom)
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2, execute: {
                        vm.showToast = false
                    })
                }
            })
            .toast(manager: toastManager)
            .onChange(of: vm.selectedImage) { _, images in
                if images.count > 0 {
                    if let firstImage = images.first {
                        vm.handleCapturedImage(firstImage)
                    }
                    if images.count > 1, let secondImage = images.last {
                        vm.handleCapturedImage(secondImage)
                    }
                    vm.selectedImage = []
                }
            }
        }
    }
    
    
}


struct CameraView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView()
    }
}

struct LoaderToastView: View {
    
    @Binding var message: String
    
    var body: some View {
        VStack {
            Spacer()
            
            HStack(spacing: 10) {
                
                ProgressView()
                    .tint(.black)
                
                Text(message)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.black)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(.white.opacity(0.9))
            .cornerRadius(12)
            .shadow(radius: 4)
        }
        .padding(.bottom, 25)
        
    }
}
