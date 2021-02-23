//
//  EditorManager.swift
//  JYVideoEditor
//
//  Created by aha on 2021/2/19.
//

import Foundation
import AVFoundation
import UIKit

public protocol EditorManagerDelegate:class {
    func managerDidInsertNewTrack(_ track: Track)
    func managerDidClipEnd()
}

public class EditorManager: NSObject {
    public weak var delegate: EditorManagerDelegate?
    
    ///需要处理的原始视频资源
    public var originAsset: AVAsset
    
    ///所使用的的所有视频通道
    public var videoTracks: [Track] = []
    ///所使用的的所有音频通道
    public var audioTracks: [Track] = []
    
    public convenience init?(source path: String, delegate: EditorManagerDelegate?) {
        let url = URL(fileURLWithPath: path)
        let asset = AVAsset(url: url)
        self.init(asset: asset, delegate: delegate)
    }
    
    /// 使用asset进行初始化，asset中必须包含视频通道，否则会返回nil
    /// - Parameter asset: 包含video通道的asset资源
    public init?(asset: AVAsset, delegate: EditorManagerDelegate?) {
        self.originAsset = asset
        guard let _ = asset.tracks(withMediaType: .video).first else {
            return nil
        }
        super.init()
        self.delegate = delegate
        configComposition()
    }
    
    //TODO: - Private
    private var outputComposition: AVMutableComposition?
    private var compositionVideoTrack: AVMutableCompositionTrack?
    private var compositiontAudioTrack: AVMutableCompositionTrack?
    
    private func configComposition() {
        let composition = AVMutableComposition()
        self.outputComposition = composition
        
        if let videoTrack = composition.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid) {
            self.compositionVideoTrack = videoTrack
        }
        if let audioTrack = composition.addMutableTrack(withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid) {
            self.compositiontAudioTrack = audioTrack
        }
        
        try? insertTrack(originAsset, type: .video, at: .zero)
    }
}

extension EditorManager {
    
    public func getComposition() -> AVMutableComposition? {
        return outputComposition
    }
    
    public func getTimeRange() -> CMTimeRange? {
        return compositionVideoTrack?.timeRange
    }
    
    public func insertTrack(_ asset: AVAsset, type: AVMediaType, at time: CMTime) throws {
        guard let track = asset.tracks(withMediaType: type).first else {
            debugPrint("资源\(asset)对应的类型\(type)的通道不存在")
            return
        }
        let compositionTrack: AVMutableCompositionTrack? = type == .video ? compositionVideoTrack : compositiontAudioTrack
        do {
            try compositionTrack?.insertTimeRange(track.timeRange, of: track, at: time)
            asset.toTrack(mediaType: type, caseSize: .init(width: 50.0, height: type == .video ? 50.0:40.0)) { (track) in
                track.insertTime = time
                if type == .video {
                    self.videoTracks.append(track)
                }else {
                    self.audioTracks.append(track)
                }
                self.delegate?.managerDidInsertNewTrack(track)
            }
        }catch {
            debugPrint("insert video track error: \(error)")
            throw error
        }
    }
    public func removeTrack(type: AVMediaType, at timeRanges: [CMTimeRange]) throws {
        let compositionTrack: AVMutableCompositionTrack? = type == .video ? compositionVideoTrack : compositiontAudioTrack
        timeRanges.forEach{ compositionTrack?.removeTimeRange($0) }
        delegate?.managerDidClipEnd()
    }
    
}
