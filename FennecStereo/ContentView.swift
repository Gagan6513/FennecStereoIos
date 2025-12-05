//
//  ContentView.swift
//  FennecStereo
//
//  Created by Hiren Nakum on 01/10/25.
//

import SwiftUI
import ReplayKit
import Photos

struct ContentView: View {
    var body: some View {
        RecorderExampleView()
//        VStack {
//            Text("📸 Wigglegram 3D Effect")
//                .font(.headline)
//                .padding()
//
////            WigglegramView(
////                leftImageName: "manmodel",
////                rightImageName: "model",
////                animationSpeed: 0.1 // adjust speed for faster or slower wiggle
////            )
////            .frame(width: 300, height: 300)
////            .clipShape(RoundedRectangle(cornerRadius: 20))
////            .shadow(radius: 5)
//        }
//        .padding()
//        .background(Color.black.opacity(0.9).ignoresSafeArea())
    }
}

//struct ContentView: View {
//    var body: some View {
//        VStack {
//            Text("🎬 Anaglyph 3D Effect")
//                .font(.headline)
//                .foregroundStyle(.white)
//                .padding(.bottom, 10)
//
//            // Example usage with adjustable offset
//            AnaglyphView(imageName: "manmodel", imageName2: "model", offset: 5)
//                .frame(width: 300, height: 200)
//                .clipped()
//        }
//        .padding()
//        .background(Color.black.ignoresSafeArea())
//    }
//}

//#Preview {
//    ContentView()
//}

struct SBSView: View {
    let firstImage: UIImage
    let secondImage: UIImage
    let offset: CGFloat

    var body: some View {
        ZStack {
            // Cyan channel
            Image(uiImage: secondImage)
                .resizable()
                .scaledToFit()
                .colorMultiply(.cyan)
                .offset(x: offset, y: 0)
                .blendMode(.screen)
                .opacity(0.8)

            // Red channel
            Image(uiImage: firstImage)
                .resizable()
                .scaledToFit()
                .colorMultiply(.red)
                .offset(x: -offset, y: 0)
                .blendMode(.screen)
                .opacity(0.8)
        }
        .background(Color.black)
        .compositingGroup()
    }
}

struct WigglegramView: View {
    let firstImage: UIImage
    let secondImage: UIImage
    let animationSpeed: Double // in seconds per switch

    @State private var showLeftImage = true

    var body: some View {
        TimelineView(.animation) { timeline in
            // Calculate which image to show based on elapsed time
            let timeInterval = timeline.date.timeIntervalSinceReferenceDate
            let phase = Int(timeInterval / animationSpeed) % 2
            let showLeft = phase == 0

            ZStack {
                if showLeft {
                    Image(uiImage: firstImage)
                        .resizable()
                        .scaledToFit()
                        .transition(.opacity)
                } else {
                    Image(uiImage: secondImage)
                        .resizable()
                        .scaledToFit()
                        .transition(.opacity)
                }
            }
        }
    }
}


struct AnaglyphView: View {
    let firstImage: UIImage
    let secondImage: UIImage
    @ObservedObject var vm: HomeViewModel

    var body: some View {
        HStack(spacing: 0) {
            imageColumn(image: firstImage)
            imageColumn(image: secondImage)
        }
    }

    @ViewBuilder
    private func imageColumn(image: UIImage) -> some View {
        VStack(spacing: 0) {
            if vm.fuseDotGuide { fuseGuide }
            Image(uiImage: image)
                .resizable()
                .scaledToFit()
        }
    }

    private var fuseGuide: some View {
        Rectangle()
            .fill(Color.white)
            .frame(height: 8)
            .overlay(
                Circle()
                    .fill(Color.black)
                    .frame(width: 4, height: 4)
            )
    }
}
