//
//  WigglegramExporter.swift
//  FennecStereo
//
//  Created by Hiren Nakum on 13/10/25.
//

import UIKit
import ImageIO
import UniformTypeIdentifiers
import MobileCoreServices
import SwiftUI
import WebKit
import ImageIO
import AVFoundation
import AVKit

struct WigglegramExporter {
    static func createAnimatedGIF(leftImage: UIImage,
                                  rightImage: UIImage,
                                  frameDelay: Double = 0.25) -> URL? {
        let fileURL = FileManager.default.temporaryDirectory.appendingPathComponent("wigglegram.gif")

        guard let destination = CGImageDestinationCreateWithURL(fileURL as CFURL,
                                                                UTType.gif.identifier as CFString,
                                                                2,
                                                                nil) else {
            return nil
        }

        let frameProperties = [
            kCGImagePropertyGIFDictionary: [
                kCGImagePropertyGIFDelayTime: frameDelay
            ]
        ]

        let gifProperties = [
            kCGImagePropertyGIFDictionary: [
                kCGImagePropertyGIFLoopCount: 0 // infinite loop
            ]
        ]

        if let left = leftImage.cgImage {
            CGImageDestinationAddImage(destination, left, frameProperties as CFDictionary)
        }

        if let right = rightImage.cgImage {
            CGImageDestinationAddImage(destination, right, frameProperties as CFDictionary)
        }

        CGImageDestinationSetProperties(destination, gifProperties as CFDictionary)

        guard CGImageDestinationFinalize(destination) else {
            print("❌ Failed to finalize GIF")
            return nil
        }

        print("✅ GIF created at:", fileURL)
        return fileURL
    }
    
}



struct AnimatedGIFView: UIViewRepresentable {
    let gifURL: URL
    
    func makeUIView(context: Context) -> UIImageView {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.backgroundColor = .clear
        imageView.clipsToBounds = true
        loadGIF(from: gifURL, into: imageView)
        return imageView
    }
    
    func updateUIView(_ uiView: UIImageView, context: Context) {
        loadGIF(from: gifURL, into: uiView)
    }
    
    private func loadGIF(from url: URL, into imageView: UIImageView) {
        guard let data = try? Data(contentsOf: url) else { return }
        imageView.image = UIImage.animatedImageWithGIFData(data)
    }

    func createWigglegramVideo(leftImage: UIImage, rightImage: UIImage, duration: Double = 2.0, fps: Int32 = 12, completion: @escaping (URL?) -> Void) {
        let size = leftImage.size
        let fileURL = FileManager.default.temporaryDirectory.appendingPathComponent("wigglegram.mp4")
        
        // Remove old file if exists
        try? FileManager.default.removeItem(at: fileURL)
        
        guard let writer = try? AVAssetWriter(outputURL: fileURL, fileType: .mp4) else {
            completion(nil)
            return
        }
        
        let settings: [String: Any] = [
            AVVideoCodecKey: AVVideoCodecType.h264,
            AVVideoWidthKey: size.width,
            AVVideoHeightKey: size.height
        ]
        let input = AVAssetWriterInput(mediaType: .video, outputSettings: settings)
        let adaptor = AVAssetWriterInputPixelBufferAdaptor(assetWriterInput: input, sourcePixelBufferAttributes: nil)
        
        writer.add(input)
        writer.startWriting()
        writer.startSession(atSourceTime: .zero)
        
        let frameDuration = CMTime(value: 1, timescale: fps)
        var frameCount: Int64 = 0
        
        let images = [leftImage, rightImage, rightImage, leftImage] // forward & backward for smooth loop
        let totalFrames = Int64(Double(images.count) * duration * Double(fps) / Double(images.count))
        
        input.requestMediaDataWhenReady(on: DispatchQueue(label: "wiggle.video.queue")) {
            while input.isReadyForMoreMediaData && frameCount < totalFrames {
                autoreleasepool {
                    let index = Int(frameCount) % images.count
                    let img = images[index]
                    if let buffer = pixelBuffer(from: img, size: size) {
                        adaptor.append(buffer, withPresentationTime: CMTimeMultiply(frameDuration, multiplier: Int32(frameCount)))
                    }
                    frameCount += 1
                }
            }
            
            input.markAsFinished()
            writer.finishWriting {
                completion(fileURL)
            }
        }
    }

    private func pixelBuffer(from image: UIImage, size: CGSize) -> CVPixelBuffer? {
        let attrs = [kCVPixelBufferCGImageCompatibilityKey: kCFBooleanTrue!,
                     kCVPixelBufferCGBitmapContextCompatibilityKey: kCFBooleanTrue!] as CFDictionary
        var buffer: CVPixelBuffer?
        CVPixelBufferCreate(kCFAllocatorDefault, Int(size.width), Int(size.height),
                            kCVPixelFormatType_32ARGB, attrs, &buffer)
        
        guard let context = buffer.flatMap({
            CVPixelBufferLockBaseAddress($0, [])
            return CGContext(
                data: CVPixelBufferGetBaseAddress($0),
                width: Int(size.width),
                height: Int(size.height),
                bitsPerComponent: 8,
                bytesPerRow: CVPixelBufferGetBytesPerRow($0),
                space: CGColorSpaceCreateDeviceRGB(),
                bitmapInfo: CGImageAlphaInfo.noneSkipFirst.rawValue
            )
        }) else { return nil }
        
        context.draw(image.cgImage!, in: CGRect(origin: .zero, size: size))
        CVPixelBufferUnlockBaseAddress(buffer!, [])
        return buffer
    }

}

private extension UIImage {
    static func animatedImageWithGIFData(_ data: Data) -> UIImage? {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil) else { return nil }
        let frameCount = CGImageSourceGetCount(source)
        var images: [UIImage] = []
        var duration: Double = 0
        
        for i in 0..<frameCount {
            guard let cgImage = CGImageSourceCreateImageAtIndex(source, i, nil) else { continue }
            let frameDuration = UIImage.frameDuration(from: source, at: i)
            duration += frameDuration
            images.append(UIImage(cgImage: cgImage))
        }
        
        return UIImage.animatedImage(with: images, duration: duration)
    }
    
    static func frameDuration(from source: CGImageSource, at index: Int) -> Double {
        guard let properties = CGImageSourceCopyPropertiesAtIndex(source, index, nil),
              let gifInfo = (properties as NSDictionary)[kCGImagePropertyGIFDictionary as String] as? NSDictionary,
              let delayTime = gifInfo[kCGImagePropertyGIFDelayTime as String] as? Double else {
            return 0.1
        }
        return delayTime
    }
}
