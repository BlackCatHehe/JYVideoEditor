//
//  Track.swift
//  JYVideoEditor
//
//  Created by aha on 2021/2/23.
//

import Foundation
import AVFoundation
import UIKit

public class Track {
    public var asset: AVAsset
    public var mediaType: AVMediaType
    public var timeRange: CMTimeRange
    public var previewImage: UIImage?
    public var insertTime: CMTime = .zero
    
    init(asset: AVAsset, mediaType: AVMediaType, previewImage: UIImage?, insertTime: CMTime = .zero) {
        self.asset = asset
        self.mediaType = mediaType
        self.previewImage = previewImage
        self.insertTime = insertTime
        if let track = asset.tracks(withMediaType: mediaType).first {
            self.timeRange = track.timeRange
        }else {
            self.timeRange = .zero
        }
    }
}

extension AVAsset {
    /// 转换为Track对象
    /// - Parameters:
    ///   - mediaType: 资源的媒体类型
    ///   - interval: 转换图片时的单位时间
    ///   - caseSize: 单位时间对应的图片大小
    ///   - result: 转换是异步的过程，在result中返回转换的结果
    func toTrack(mediaType: AVMediaType, interval: Double = 1.0, caseSize: CGSize, result: ((Track) -> Void)?) {
        if mediaType == .video {
            generatePreviewImage(interval: 1.0, caseSize: caseSize, result: {[weak self] img in
                guard let self = self else {
                    return
                }
                let track = Track(asset: self, mediaType: mediaType, previewImage: img)
                result?(track)
            })
        }else {
            let img = generateAudioToWaves(interval: interval, caseSize: caseSize)
            let track = Track(asset: self, mediaType: mediaType, previewImage: img)
            result?(track)
        }
    }
}
