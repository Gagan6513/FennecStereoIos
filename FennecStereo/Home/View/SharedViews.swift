//
//  BlurView.swift
//  FennecStereo
//
//  Created by Kushkumar on 08/10/25.
//
import SwiftUI

struct CameraTopButton: View {
    var icon: String
    var title: String
    var isHighlighted: Bool = false

    var body: some View {
        VStack(spacing: 4) {
            switch TopOptionsTitle(rawValue: title) {
            case .anaglyph, .sbs, .wigglegram :
                Image(icon)
                    .resizable()
                    .frame(width: 16, height: 16)
            default:
                Image(systemName: icon)
                    .frame(width: 16, height: 16)
                    .font(.footnote)
                    .foregroundColor(isHighlighted ? .yellow : .white)
            }
            
            Text(title)
                .font(.system(size: 12, weight: .light))
                .foregroundColor(isHighlighted ? .yellow : .white)
        }
    }
}

struct CameraBottomButton: View {
    var icon: String
    var title: String
    var isHighlighted: Bool = false

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.footnote)
                .foregroundColor(isHighlighted ? .yellow : .white)
            Text(title)
                .font(.system(size: 12, weight: .light))
                .foregroundColor(isHighlighted ? .yellow : .white)
        }
    }
}

struct CustomSlider: View {
    @Binding var value: CGFloat

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Capsule().fill(Color.gray.opacity(0.7)).frame(height: 15)
                Capsule().fill(Color.white).frame(width: value * geometry.size.width, height: 15)
                Capsule().fill(Color.white.opacity(0.9)).frame(width: 5, height: 40)
                    .offset(x: value * (geometry.size.width - 5))
            }
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { gesture in
                        let newValue = gesture.location.x / geometry.size.width
                        value = min(max(newValue, 0), 1)
                    }
            )
        }
        .frame(height: 40)
    }
}

struct DeniedCameraView: View {
    var body: some View {
        VStack(spacing: 16) {
            Spacer()
            
            Text("To use this feature, camera access is required. Since you have denied permission, please enable it manually from the app settings.")
                .font(.footnote)
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .padding()
            
            Button("Go to Settings") {
                if let appSettings = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(appSettings)
                }
            }
            .font(.footnote)
            .padding(.horizontal)
            .padding(.vertical, 5)
            .background(Border.color(border: .backGround))
            .foregroundColor(.white)
            .clipShape(Capsule())
            
            Spacer()
        }
        .background(Border.color(border: .offBlack))
        
    }
}

struct ImageRendererView: View {
    let firstImage: UIImage
    let secondImage: UIImage
    let isRotate: Bool

    var body: some View {
        HStack(spacing: 2) {
            Image(uiImage: firstImage).resizable().scaledToFit()
            Image(uiImage: secondImage).resizable().scaledToFit()
        }
        .frame(height: 300)
        .padding()
        .rotationEffect(isRotate ? .degrees(90) : .degrees(0))
        .background(Color.black)
    }
}

// For background blur
struct BlurView: UIViewRepresentable {
    let style: UIBlurEffect.Style
    func makeUIView(context: Context) -> UIVisualEffectView {
        UIVisualEffectView(effect: UIBlurEffect(style: style))
    }
    func updateUIView(_ uiView: UIVisualEffectView, context: Context) {}
}
