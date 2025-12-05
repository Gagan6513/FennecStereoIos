//
//  ImageCropperView.swift
//  FennecStereo
//
//  Created by Kushkumar on 16/10/25.
//

//
//  ImageCropperView.swift
//  FennecStereo
//
//  Created by Kushkumar on 16/10/25.
//

import SwiftUI
import CoreGraphics
import UIKit

// MARK: - Result Structure
struct TwoImageCroppedResults {
    let image1: UIImage
    let image2: UIImage
}

// MARK: - Crop Enums and Helpers
private enum Corner { case topLeft, topRight, bottomLeft, bottomRight }

// MARK: - TwoImageCropperView (drop-in replacement with real-time drag)
struct TwoImageCropperView: View {
    @ObservedObject var vm: HomeViewModel

    let uiImage1: UIImage
    let uiImage2: UIImage
    let onCrop: (TwoImageCroppedResults) -> Void

    // Crop rect in the displayed image coordinate space (origin is top-left of displayed image)
    @State private var cropOrigin: CGPoint = .zero
    @State private var cropSize: CGSize

    // Temporary gesture states
    @GestureState private var dragTranslation: CGSize = .zero        // For moving the box
    @GestureState private var cornerDragTranslation: CGSize = .zero  // For resizing the box
    @GestureState private var activeCorner: Corner? = nil            // NEW: Tracks which corner is being resized

    // minimal size for the crop rect
    private let minCropSize: CGFloat = 64

    init(vm: HomeViewModel, uiImage1: UIImage, uiImage2: UIImage,
         initialCropSize: CGSize? = nil,
         onCrop: @escaping (TwoImageCroppedResults) -> Void) {

        self.vm = vm
        self.uiImage1 = uiImage1
        self.uiImage2 = uiImage2
        self.onCrop = onCrop

        let defaultSize = initialCropSize ?? CGSize(width: 300, height: 180)

        // Adjust crop size to match image aspect ratio
        let imageAspect = uiImage1.size.width / uiImage1.size.height
        let defaultAspect = defaultSize.width / defaultSize.height

        var adjustedWidth = defaultSize.width
        var adjustedHeight = defaultSize.height

        if abs(defaultAspect - imageAspect) > 0.01 {
            // Match aspect ratio to image (attempt to preserve ratio visually initially)
            if defaultAspect > imageAspect {
                adjustedWidth = defaultSize.height * imageAspect
            } else {
                adjustedHeight = defaultSize.width / imageAspect
            }
        }

        _cropSize = State(initialValue: CGSize(width: adjustedWidth, height: adjustedHeight))
    }
    
    // MARK: - Transient Rect Calculation (The core change for smoothness)
    
    private func transientCropRect() -> CGRect {
        var origin = cropOrigin
        var size = cropSize
        
        if dragTranslation != .zero {
            // 1. Move gesture is active
            origin.x += dragTranslation.width
            origin.y += dragTranslation.height
        } else if cornerDragTranslation != .zero, let corner = activeCorner {
            // 2. Corner resize gesture is active
            let t = cornerDragTranslation

            // Apply the temporary translation to origin and size based on the corner
            switch corner {
            case .topLeft:
                origin.x += t.width; origin.y += t.height
                size.width -= t.width; size.height -= t.height
            case .topRight:
                origin.y += t.height
                size.width += t.width; size.height -= t.height
            case .bottomLeft:
                origin.x += t.width
                size.width -= t.width; size.height += t.height
            case .bottomRight:
                size.width += t.width; size.height += t.height
            }
            
            // Simple visual clamping (full clamping happens on onEnded)
            size.width = max(size.width, minCropSize)
            size.height = max(size.height, minCropSize)
        }
        
        return CGRect(origin: origin, size: size)
    }

    var body: some View {
        GeometryReader { geo in
            let containerSize = geo.size

            let displayedImageFrame = calculateImageFrame(for: uiImage1, in: containerSize)
            
            // NEW: Use the transient rect for all positioning/sizing
            let transientRect = transientCropRect()
            let effectiveOrigin = transientRect.origin
            let effectiveSize = transientRect.size

            ZStack {
                // Fixed background image 1 (Bottom layer)
                Image(uiImage: uiImage1)
                    .resizable()
                    .scaledToFit()
                    .frame(width: displayedImageFrame.size.width, height: displayedImageFrame.size.height)
                    .position(x: displayedImageFrame.midX, y: displayedImageFrame.midY)

                // Fixed background image 2 (Top layer)
                Image(uiImage: uiImage2)
                    .resizable()
                    .scaledToFit()
                    .frame(width: displayedImageFrame.size.width, height: displayedImageFrame.size.height)
                    .position(x: displayedImageFrame.midX, y: displayedImageFrame.midY)
                    .opacity(0.5)

                // Overlay hole
                CropOverlayView(
                    containerSize: containerSize,
                    imageFrame: displayedImageFrame,
                    cropOrigin: effectiveOrigin, // NEW: Use transient origin
                    cropSize: effectiveSize      // NEW: Use transient size
                    // REMOVED dragTranslation
                )
                .allowsHitTesting(false)

                // Movable crop box with handles
                Group {
                    // Visible rectangle border and grid lines
                    CropGridView(size: effectiveSize) // NEW: Use effectiveSize
                        .frame(width: effectiveSize.width, height: effectiveSize.height)
                        // NEW: Position using effectiveOrigin and effectiveSize
                        .position(x: displayedImageFrame.minX + effectiveOrigin.x + effectiveSize.width / 2,
                                  y: displayedImageFrame.minY + effectiveOrigin.y + effectiveSize.height / 2)
                        .gesture(
                            DragGesture()
                                .updating($dragTranslation) { v, state, _ in state = v.translation }
                                .onEnded { v in
                                    let newOrigin = CGPoint(x: cropOrigin.x + v.translation.width,
                                                            y: cropOrigin.y + v.translation.height)
                                    cropOrigin = clampOrigin(newOrigin, cropSize: cropSize, imageFrame: displayedImageFrame)
                                }
                        )

                    // Corner handles
                    // NEW: Position handles using effectiveOrigin and effectiveSize
                    cornerHandle
                        .position(x: displayedImageFrame.minX + effectiveOrigin.x + 12, y: displayedImageFrame.minY + effectiveOrigin.y + 12)
                        .gesture(cornerDrag(.topLeft, displayedImageFrame: displayedImageFrame))
                    cornerHandle
                        .position(x: displayedImageFrame.minX + effectiveOrigin.x + effectiveSize.width - 12, y: displayedImageFrame.minY + effectiveOrigin.y + 12)
                        .gesture(cornerDrag(.topRight, displayedImageFrame: displayedImageFrame))
                    cornerHandle
                        .position(x: displayedImageFrame.minX + effectiveOrigin.x + 12, y: displayedImageFrame.minY + effectiveOrigin.y + effectiveSize.height - 12)
                        .gesture(cornerDrag(.bottomLeft, displayedImageFrame: displayedImageFrame))
                    cornerHandle
                        .position(x: displayedImageFrame.minX + effectiveOrigin.x + effectiveSize.width - 12, y: displayedImageFrame.minY + effectiveOrigin.y + effectiveSize.height - 12)
                        .gesture(cornerDrag(.bottomRight, displayedImageFrame: displayedImageFrame))
                }
                .frame(width: containerSize.width, height: containerSize.height)
            }
            .onAppear {
                let cropRect = initialCropRect(for: displayedImageFrame)
                cropOrigin = CGPoint(x: cropRect.minX, y: cropRect.minY)
                cropSize = CGSize(width: cropRect.width, height: cropRect.height)
            }
            .onChange(of: vm.cropPress) { _, newValue in
                if newValue {
                    if let cropped = self.cropImages(in: displayedImageFrame) {
                        self.onCrop(cropped)
                    } else {
                        print("Crop failed for one or both images.")
                    }
                }
            }
        }
    }

    // Compute initial crop size in displayed image coordinates
    private func initialCropRect(for displayedImageFrame: CGRect) -> CGRect {
        // Use vm preview sizes as your default desired crop
        let desiredWidth = vm.previewWidth
        let desiredHeight = vm.previewHeight

        let imageAspect = uiImage1.size.width / uiImage1.size.height
        let desiredAspect = desiredWidth / desiredHeight

        var cropWidth = desiredWidth
        var cropHeight = desiredHeight

        if desiredAspect > imageAspect {
            cropWidth = cropHeight * imageAspect
        } else {
            cropHeight = cropWidth / imageAspect
        }

        cropWidth = min(cropWidth, displayedImageFrame.width)
        cropHeight = min(cropHeight, displayedImageFrame.height)

        let originX = (displayedImageFrame.width - cropWidth) / 2
        let originY = (displayedImageFrame.height - cropHeight) / 2

        return CGRect(x: originX, y: originY, width: cropWidth, height: cropHeight)
    }

    // MARK: - Helper Views and Logic

    private var cornerHandle: some View {
        RoundedRectangle(cornerRadius: 4)
            .fill(Color.white)
            .frame(width: 24, height: 24)
            .shadow(radius: 1)
    }

    private func cornerDrag(_ corner: Corner, displayedImageFrame: CGRect) -> some Gesture {
        DragGesture()
            // NEW: Update translation and the active corner flag in real-time
            .updating($cornerDragTranslation) { v, state, _ in state = v.translation }
            .updating($activeCorner) { _, state, _ in state = corner }
            .onEnded { v in
                // The onEnded logic remains the same (it commits the final, clamped values)
                var origin = cropOrigin
                var size = cropSize
                let t = v.translation

                switch corner {
                case .topLeft:
                    origin.x += t.width; origin.y += t.height
                    size.width -= t.width; size.height -= t.height
                case .topRight:
                    origin.y += t.height
                    size.width += t.width; size.height -= t.height
                case .bottomLeft:
                    origin.x += t.width
                    size.width -= t.width; size.height += t.height
                case .bottomRight:
                    size.width += t.width; size.height += t.height
                }

                size.width = max(size.width, minCropSize)
                size.height = max(size.height, minCropSize)

                let clampedOrigin = clampOrigin(origin, cropSize: size, imageFrame: displayedImageFrame)

                var maxW = displayedImageFrame.width - clampedOrigin.x
                var maxH = displayedImageFrame.height - clampedOrigin.y
                maxW = max(maxW, minCropSize)
                maxH = max(maxH, minCropSize)
                size.width = min(size.width, maxW)
                size.height = min(size.height, maxH)

                var finalOrigin = clampedOrigin
                if finalOrigin.x < 0 { size.width += finalOrigin.x; finalOrigin.x = 0 }
                if finalOrigin.y < 0 { size.height += finalOrigin.y; finalOrigin.y = 0 }

                size.width = max(size.width, minCropSize)
                size.height = max(size.height, minCropSize)

                cropOrigin = finalOrigin
                cropSize = size
                
                // Active corner is reset automatically by @GestureState
            }
    }

    private func clampOrigin(_ origin: CGPoint, cropSize: CGSize, imageFrame: CGRect) -> CGPoint {
        var x = origin.x
        var y = origin.y
        x = min(max(0, x), imageFrame.width - cropSize.width)
        y = min(max(0, y), imageFrame.height - cropSize.height)
        return CGPoint(x: x, y: y)
    }

    private func calculateImageFrame(for image: UIImage, in container: CGSize) -> CGRect {
        let imageAspect = image.size.width / image.size.height
        let containerAspect = container.width / container.height

        var drawnWidth: CGFloat
        var drawnHeight: CGFloat

        if imageAspect > containerAspect {
            drawnWidth = container.width
            drawnHeight = container.width / imageAspect
        } else {
            drawnHeight = container.height
            drawnWidth = container.height * imageAspect
        }

        let originX = (container.width - drawnWidth) / 2
        let originY = (container.height - drawnHeight) / 2

        return CGRect(x: originX, y: originY, width: drawnWidth, height: drawnHeight)
    }

    // MARK: - Cropping Logic (pixel accurate, handles retina & orientation)
    private func cropImages(in displayedImageFrame: CGRect) -> TwoImageCroppedResults? {
        // Use the committed (non-transient) crop state for the final crop
        let cropRectInContainer = CGRect(
            x: displayedImageFrame.minX + cropOrigin.x,
            y: displayedImageFrame.minY + cropOrigin.y,
            width: cropSize.width,
            height: cropSize.height
        )

        func performCrop(originalImage: UIImage) -> UIImage? {
            // Normalize image to a cgImage in .up orientation so mapping is simple
            guard let sourceCG = normalizedCGImage(from: originalImage) else { return nil }

            let cgWidth = CGFloat(sourceCG.width)
            let cgHeight = CGFloat(sourceCG.height)

            // displayedImageFrame is in points; sourceCG is in pixels.
            // Calculate pixel-per-point scaling used for the displayed image (should be uniform).
            let pxPerPointX = cgWidth / displayedImageFrame.width
            let pxPerPointY = cgHeight / displayedImageFrame.height

            // Map crop rect (in points relative to displayedImageFrame origin) -> pixels
            let relX = cropRectInContainer.minX - displayedImageFrame.minX
            let relY = cropRectInContainer.minY - displayedImageFrame.minY

            let cropX = relX * pxPerPointX
            let cropY = relY * pxPerPointY
            let cropW = cropRectInContainer.width * pxPerPointX
            let cropH = cropRectInContainer.height * pxPerPointY

            // Round and clamp to image pixel bounds
            var croppingRect = CGRect(x: round(cropX), y: round(cropY), width: round(cropW), height: round(cropH))
            let imgBounds = CGRect(x: 0, y: 0, width: cgWidth, height: cgHeight)
            croppingRect = croppingRect.intersection(imgBounds)

            guard croppingRect.width > 0 && croppingRect.height > 0 else { return nil }
            guard let croppedCG = sourceCG.cropping(to: croppingRect) else { return nil }

            // Return a UIImage with same scale as original (or 1.0). Use .up orientation because we normalized.
            return UIImage(cgImage: croppedCG, scale: originalImage.scale, orientation: .up)
        }

        // Shortcut when crop covers full displayed image
        if cropOrigin == .zero && cropSize == displayedImageFrame.size {
            return TwoImageCroppedResults(image1: uiImage1, image2: uiImage2)
        }

        guard let c1 = performCrop(originalImage: uiImage1),
              let c2 = performCrop(originalImage: uiImage2) else {
            return nil
        }
        return TwoImageCroppedResults(image1: c1, image2: c2)
    }

    // Normalize UIImage to CGImage with upright orientation (pixels)
    private func normalizedCGImage(from image: UIImage) -> CGImage? {
        if image.imageOrientation == .up, let cg = image.cgImage {
            return cg
        }

        // Draw into context to normalize orientation
        let targetSize = CGSize(width: image.size.width * image.scale, height: image.size.height * image.scale)
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        guard let ctx = CGContext(data: nil,
                                  width: Int(targetSize.width),
                                  height: Int(targetSize.height),
                                  bitsPerComponent: 8,
                                  bytesPerRow: 0,
                                  space: colorSpace,
                                  bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)
        else { return nil }

        // Flip coordinate system for UIKit drawing
        ctx.translateBy(x: 0, y: targetSize.height)
        ctx.scaleBy(x: 1.0, y: -1.0)

        // Draw the UIImage into the context (this correctly applies orientation)
        UIGraphicsPushContext(ctx)
        image.draw(in: CGRect(origin: .zero, size: targetSize))
        UIGraphicsPopContext()

        return ctx.makeImage()
    }
}

// MARK: - CropGridView and CropOverlayView (Modified)
private struct CropGridView: View {
    let size: CGSize

    var body: some View {
        ZStack {
            Rectangle()
                .stroke(Color.white, lineWidth: 2)
                .background(Color.clear)

            Path { path in
                for i in 1..<3 {
                    let x = size.width / 3 * CGFloat(i)
                    path.move(to: CGPoint(x: x, y: 0))
                    path.addLine(to: CGPoint(x: x, y: size.height))

                    let y = size.height / 3 * CGFloat(i)
                    path.move(to: CGPoint(x: 0, y: y))
                    path.addLine(to: CGPoint(x: size.width, y: y))
                }
            }
            .stroke(Color.white.opacity(0.8), lineWidth: 1)
        }
    }
}

private struct CropOverlayView: View {
    let containerSize: CGSize
    let imageFrame: CGRect
    let cropOrigin: CGPoint // NOW the effective/transient origin
    let cropSize: CGSize    // NOW the effective/transient size
    // REMOVED: let dragTranslation: CGSize

    var body: some View {
        // The effective crop rect is built using the (already translated) cropOrigin and cropSize
        let cropRectInContainer = CGRect(
            x: imageFrame.minX + cropOrigin.x,
            y: imageFrame.minY + cropOrigin.y,
            width: cropSize.width,
            height: cropSize.height
        )

        return Canvas { context, size in
            context.fill(Path(CGRect(origin: .zero, size: size)), with: .color(Color.black.opacity(0.45)))

            let path = Path(cropRectInContainer)
            context.blendMode = .clear
            context.fill(path, with: .color(.white))
        }
        .frame(width: containerSize.width, height: containerSize.height)
        .allowsHitTesting(false)
    }
}

// MARK: - CropView (Container)
struct CropView: View {
    
    @ObservedObject var vm: HomeViewModel

    var body: some View {
        VStack {
            
            if let firstImage = vm.originalFirstImage, let secondImage = vm.originalSecondImage {
                
                TwoImageCropperView(
                    vm: vm, uiImage1: firstImage,
                    uiImage2: secondImage,
                    initialCropSize: CGSize(width: vm.previewWidth, height: vm.previewHeight)
                ) { result in
                    
                    print("Crop successful. Image 1 cropped size: \(result.image1.size)")
                    print("Crop successful. Image 2 cropped size: \(result.image2.size)")
                    
                    vm.firstImage = result.image1
                    vm.secondImage = result.image2
                    
                    vm.isCropOn = false
                    vm.cropPress = false
                }
                .frame(height: vm.previewHeight)
                .border(Color.gray)
            }
        }
    }
}
