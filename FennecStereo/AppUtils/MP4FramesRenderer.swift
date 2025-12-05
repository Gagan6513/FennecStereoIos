
import Foundation
import AVFoundation
import UIKit
import Combine
//import SwiftUIViewRecorder

public class MP4FramesRenderer: FramesRenderer {
    public typealias Asset = URL

    private let outputURL: URL
    private let videoSize: CGSize
    private let fileType: AVFileType

    public init(outputURL: URL,
                videoSize: CGSize = CGSize(width: 720, height: 1280),
                fileType: AVFileType = .mp4) {
        
        print("videoSize ", videoSize)
        
        //let widthRatio = videoSize.width / 720
        //let heightRatio = videoSize.height / 1280
        
        let finalSize = CGSize(width: 720, height: 1080)
        
       // print("finalSize ", finalSize)
        
        self.outputURL = outputURL
        self.videoSize = finalSize
        self.fileType = fileType
    }

    public func render(frames: [UIImage], framesPerSecond: Double) -> Future<URL?, Error> {
        return Future { promise in
            guard !frames.isEmpty else {
                promise(.failure(NSError(domain: "MP4FramesRenderer", code: -1, userInfo: [NSLocalizedDescriptionKey: "No frames to render"])))
                return
            }

            // Remove file if already exists
            try? FileManager.default.removeItem(at: self.outputURL)

            // Prepare AVAssetWriter
            guard let writer = try? AVAssetWriter(outputURL: self.outputURL, fileType: self.fileType) else {
                promise(.failure(NSError(domain: "MP4FramesRenderer", code: -2, userInfo: [NSLocalizedDescriptionKey: "Unable to start AVAssetWriter"])))
                return
            }

            let settings: [String: Any] = [
                AVVideoCodecKey: AVVideoCodecType.h264,
                AVVideoWidthKey: self.videoSize.width,
                AVVideoHeightKey: self.videoSize.height,
                AVVideoCompressionPropertiesKey: [
                        AVVideoAverageBitRateKey: 6_000_000, // ✅ Higher bitrate = sharper video
                        AVVideoProfileLevelKey: AVVideoProfileLevelH264HighAutoLevel
                    ]
            ]

            let writerInput = AVAssetWriterInput(mediaType: .video, outputSettings: settings)
            let adaptor = AVAssetWriterInputPixelBufferAdaptor(assetWriterInput: writerInput,
                                                               sourcePixelBufferAttributes: nil)

            guard writer.canAdd(writerInput) else {
                promise(.failure(NSError(domain: "MP4FramesRenderer", code: -3, userInfo: [NSLocalizedDescriptionKey: "Cannot add input"])))
                return
            }
            writer.add(writerInput)

            writer.startWriting()
            writer.startSession(atSourceTime: .zero)

            let frameDuration = CMTime(value: 1, timescale: CMTimeScale(framesPerSecond))
            var frameCount: Int64 = 0

            writerInput.requestMediaDataWhenReady(on: DispatchQueue(label: "videoQueue")) {
                for frame in frames {
                    if !writerInput.isReadyForMoreMediaData { break }

                    guard let buffer = frame.pixelBuffer(size: self.videoSize) else { continue }
                    let time = CMTimeMultiply(frameDuration, multiplier: Int32(frameCount))
                    adaptor.append(buffer, withPresentationTime: time)
                    frameCount += 1
                }

                writerInput.markAsFinished()
                writer.finishWriting {
                    if writer.status == .completed {
                        promise(.success(self.outputURL))
                    } else {
                        promise(.failure(writer.error ?? NSError(domain: "MP4FramesRenderer", code: -4)))
                    }
                }
            }
        }
    }
}

// Helper to convert UIImage to CVPixelBuffer
extension UIImage {
    func pixelBuffer(size: CGSize) -> CVPixelBuffer? {
        var pixelBuffer: CVPixelBuffer?
        let attrs = [
            kCVPixelBufferCGImageCompatibilityKey: true,
            kCVPixelBufferCGBitmapContextCompatibilityKey: true
        ] as CFDictionary

        let status = CVPixelBufferCreate(kCFAllocatorDefault,
                                         Int(size.width),
                                         Int(size.height),
                                         kCVPixelFormatType_32ARGB,
                                         attrs,
                                         &pixelBuffer)
        guard status == kCVReturnSuccess, let buffer = pixelBuffer else {
            return nil
        }

        CVPixelBufferLockBaseAddress(buffer, [])
        let context = CGContext(
            data: CVPixelBufferGetBaseAddress(buffer),
            width: Int(size.width),
            height: Int(size.height),
            bitsPerComponent: 8,
            bytesPerRow: CVPixelBufferGetBytesPerRow(buffer),
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.noneSkipFirst.rawValue
        )

        if let cgImage = self.cgImage {
            context?.draw(cgImage, in: CGRect(origin: .zero, size: size))
        }

        CVPixelBufferUnlockBaseAddress(buffer, [])
        return buffer
    }
}
