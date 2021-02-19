//
//  AVAsset+Generate.swift
//  JYVideoEditor
//
//  Created by aha on 2021/2/19.
//

import AVFoundation
import Foundation
import UIKit

extension AVAsset {
    func generatePreviewImage(with interval: TimeInterval, caseSize: CGSize, result: ((UIImage?) -> Void)?) {
        generateAllPreviewSnapshop(interval: interval) { (imgs) in
            DispatchQueue.main.async {
                let img = self.compositionImages(imgs, size: caseSize)
                result?(img)
            }
        }
    }
    
    private func compositionImages(_ imgs: [UIImage], size: CGSize) -> UIImage? {
        let width: CGFloat = size.width
        let height: CGFloat = size.height
        let seconds = self.tracks(withMediaType: .video).first?.timeRange.duration.seconds ?? 0.0
        let size = CGSize(width: CGFloat(seconds) * width, height: height)
        
        UIGraphicsBeginImageContext(size)
        for i in 0..<imgs.count {
            let rect = CGRect.init(x: width * CGFloat(i), y: 0, width: width, height: height)
            imgs[i].draw(in: rect)
        }
        let img = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return img
    }
    
    private func generateAllPreviewSnapshop(interval: TimeInterval, complete: @escaping ([UIImage]) -> Void) {
        guard let videoTrack = tracks(withMediaType: .video).first else {
            return
        }
        let generator = AVAssetImageGenerator(asset: self)
        generator.requestedTimeToleranceAfter = .zero
        generator.requestedTimeToleranceBefore = .zero

        var times = [CMTime]()
        let needsImageCount = Int(videoTrack.timeRange.duration.seconds / interval)
        for i in 0...needsImageCount {
            let time = CMTime(seconds: Double(i) * interval, preferredTimescale: videoTrack.timeRange.duration.timescale)
            times.append(time)
        }
        let results = times.map { NSValue(time: $0) }
        var resultImages = [(CMTime, UIImage)]()

        let totalCount = needsImageCount
        var currentCount = 0
        generator.generateCGImagesAsynchronously(forTimes: results) { (_, imgRef, actualTime, result, err) in
            currentCount += 1
            if result == .succeeded, let imageRef = imgRef {
                let img = UIImage(cgImage: imageRef)
                resultImages.append((actualTime, img))
            } else {
                print("generator snapshot failed: \(err)")
            }
            if currentCount >= totalCount {
                let resultImgs = resultImages.sorted { (result1, result2) -> Bool in
                    result1.0 < result2.0
                }.map { $0.1 }
                complete(resultImgs)
            }
        }
    }
}
