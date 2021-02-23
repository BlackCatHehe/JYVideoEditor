//
//  UIImage+ConvertVideo.swift
//  JYVideoEditor
//
//  Created by aha on 2021/2/20.
//

import Foundation
import UIKit
import AVFoundation
extension Array where Element: UIImage {
    ///将图片转换为视频
    func convertToVideos(complete: ((URL) -> Void)?) {
        let imagesPixelBuffers: [CVPixelBuffer] = self.compactMap{ $0.convertToCVPixelBufferRef() }
        guard imagesPixelBuffers.isEmpty == false else {
            print("create cmsamplebuffer error")
            return
        }

        guard let cachesFolderUrl = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first else {
            return
        }
        print("caches folder: \(cachesFolderUrl)")
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "YYYY-MM-dd hh:mm:ss"
        let dateString = dateFormatter.string(from: Date())
        let outputUrl = cachesFolderUrl.appendingPathComponent("image_convert_\(dateString).mp4")

        do {
            let writer = try AVAssetWriter(outputURL: outputUrl, fileType: .mp4)

            var videoSettings = [
                AVVideoCodecKey: AVVideoCodecH264,
                AVVideoWidthKey: 515,
                AVVideoHeightKey: 300
            ] as [String: Any]
            if #available(iOS 11.0, *) {
                videoSettings = [
                    AVVideoCodecKey: AVVideoCodecType.h264,
                    AVVideoWidthKey: 515,
                    AVVideoHeightKey: 300
                ] as [String: Any]
            }
            let writerInput = AVAssetWriterInput(mediaType: .video, outputSettings: videoSettings)

            let adaptor = AVAssetWriterInputPixelBufferAdaptor(assetWriterInput: writerInput, sourcePixelBufferAttributes: [(kCVPixelBufferPixelFormatTypeKey as String): kCVPixelFormatType_32ABGR])

            if writer.canAdd(writerInput) {
                writer.add(writerInput)
                writer.startWriting()
                writer.startSession(atSourceTime: .zero)
                var i = 0
                writerInput.requestMediaDataWhenReady(on: .global()) {
                    while writerInput.isReadyForMoreMediaData {
                        if i >= 90 * imagesPixelBuffers.count {
                            writerInput.markAsFinished()
                            writer.finishWriting {
                                print("writing finished")
                                complete?(outputUrl)
                            }
                            return
                        }
                        if adaptor.append(imagesPixelBuffers[i / 90], withPresentationTime: .init(value: CMTimeValue(i), timescale: 30)) {
                            print("append cvpixelbuffer success")
                        } else {
                            print("append cvpixelbuffer fail")
                        }
                        i += 1
                        return
                    }

                }
            } else {
                print("cannot add writerInput")
            }
        } catch {
            print("init writer failed: \(error)")
        }
    }
}

extension UIImage {
    
    ///压缩图片到指定的大小
    func compressImage(size: CGSize) -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(size, false, 0)
        draw(in: .init(origin: .zero, size: size))
        guard let img = UIGraphicsGetImageFromCurrentImageContext() else {
            return nil
        }
        guard let imgData = img.jpegData(compressionQuality: 0.3) else {
            return nil
        }
        UIGraphicsEndImageContext()
        return UIImage(data: imgData)
    }

    ///将图片转换为CVPixelBufferRef
    func convertToCVPixelBufferRef() -> CVPixelBuffer? {
        guard let cgImage = cgImage else {
            print("get cgImage error")
            return nil
        }

        let options = [
            kCVPixelBufferCGImageCompatibilityKey: true,
            kCVPixelBufferCGBitmapContextCompatibilityKey: true
        ]
        var pb: CVPixelBuffer?
        let status = CVPixelBufferCreate(kCFAllocatorDefault, Int(size.width), Int(size.height), kCVPixelFormatType_32ARGB, (options as NSDictionary), &pb)
        guard status == kCVReturnSuccess, let pixelBuffer = pb else {
            print("create pixel buffer error: \(status)")
            return nil ;
            
            
        }
        CVPixelBufferLockBaseAddress(pixelBuffer, .init(rawValue: 0))

        guard let pxData = CVPixelBufferGetBaseAddress(pixelBuffer) else {
            print("get pxData error")
            return nil
        }
        let rgbColorSpace = CGColorSpaceCreateDeviceRGB()
        // swiftlint:disable:next line_length
        guard let context = CGContext.init(data: pxData, width: Int(size.width), height: Int(size.height), bitsPerComponent: 8, bytesPerRow: CVPixelBufferGetBytesPerRow(pixelBuffer), space: rgbColorSpace, bitmapInfo: CGImageAlphaInfo.premultipliedFirst.rawValue) else {
            print("get context error")
            return nil
        }
        context.concatenate(.identity)

        context.draw(cgImage, in: .init(origin: .zero, size: size))

        CVPixelBufferUnlockBaseAddress(pixelBuffer, .init(rawValue: 0))
        return pixelBuffer

        //        var sampleBuffer: CMSampleBuffer?
        //        var formatDesc: CMFormatDescription? = nil
        //        CMVideoFormatDescriptionCreateForImageBuffer(allocator: kCFAllocatorDefault, imageBuffer: pixelBuffer, formatDescriptionOut: &formatDesc)
        //        guard let fd = formatDesc else {
        //            return nil
        //        }
        //        var timingInfo = CMSampleTimingInfo(duration: .invalid,
        //                                            presentationTimeStamp: .invalid,
        //                                            decodeTimeStamp: .invalid)
        //
        //        CMSampleBufferCreateReadyWithImageBuffer(allocator: kCFAllocatorDefault, imageBuffer: pixelBuffer, formatDescription: fd, sampleTiming: &timingInfo, sampleBufferOut: &sampleBuffer)
        //        return sampleBuffer
    }
}
