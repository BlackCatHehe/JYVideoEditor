//
//  EditorViewController.swift
//  JYVideoEditor
//
//  Created by aha on 2021/2/19.
//

import UIKit
import AVKit
class EditorViewController: UIViewController {

    var sourcePath: String!
    
    @IBOutlet private weak var playerView: UIView!
    @IBOutlet weak var trackPreviewView: TrackPreviewView!
    private var player: AVPlayer!
    private var editorManager: EditorManager!
    private var playerTimerToken: Any?
    static func instance(sourcePath: String) -> EditorViewController {
        let editorVC = EditorViewController.loadInstanceFromSB() as! EditorViewController
        editorVC.sourcePath = sourcePath
        return editorVC
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
}
extension EditorViewController {
    
    private func setupUI() {
        let asset = AVAsset(url: URL(fileURLWithPath: sourcePath))
        editorManager = EditorManager(asset: asset, delegate: self)
        
        trackPreviewView.manager = editorManager
        trackPreviewView.delegate = self
        
        
        let playerVC = AVPlayerViewController()
        playerVC.player = AVPlayer(playerItem: .init(asset: editorManager.getComposition()!))
        self.player = playerVC.player
        addChild(playerVC)
        playerView.addSubview(playerVC.view)
        playerVC.view.translatesAutoresizingMaskIntoConstraints = false
        playerVC.view.leadingAnchor.constraint(equalTo: playerView.leadingAnchor).isActive = true
        playerVC.view.trailingAnchor.constraint(equalTo: playerView.trailingAnchor).isActive = true
        playerVC.view.topAnchor.constraint(equalTo: playerView.topAnchor).isActive = true
        playerVC.view.bottomAnchor.constraint(equalTo: playerView.bottomAnchor).isActive = true
        
    }
}
extension EditorViewController {
    private func updatePlayer() {
        if let composition = editorManager.getComposition() {
            let item = AVPlayerItem(asset: composition)
            player.replaceCurrentItem(with: item)
            
            if let token = self.playerTimerToken {
                player.removeTimeObserver(token)
            }
            if let timeRange = editorManager.getTimeRange() {
                self.playerTimerToken = player.addPeriodicTimeObserver(forInterval: .init(seconds: 0.01, preferredTimescale: timeRange.duration.timescale), queue: .main) {[weak self] (time) in
                    self?.trackPreviewView.progress = time.seconds / timeRange.duration.seconds
                }
            }
        }
    }
}

extension EditorViewController: TrackPreviewViewDelegate {
    func trackPreviewDidScroll(progress: Double) {
        //正在播放
        if self.player.rate != 0 && player.error == nil {
            player.pause()
        }
        if let timeRange = editorManager.getTimeRange() {
            let playTime = timeRange.duration
            let p = min(1.0, max(0, progress))
            let time = CMTime(seconds: playTime.seconds * p, preferredTimescale: playTime.timescale)
            player.seek(to: time, toleranceBefore: .zero, toleranceAfter: .zero)
        }
        
    }
}

extension EditorViewController: EditorManagerDelegate {
    func managerDidInsertNewTrack(_ track: Track) {
        let currentTime = self.player.currentTime()
        if let totalSeconds = editorManager.getTimeRange()?.duration.seconds {
            
            let progress = currentTime.seconds / totalSeconds
            trackPreviewView.insertTrack(track: track, progress: progress)
        }else {
            trackPreviewView.insertTrack(track: track, progress: 0)
        }
        updatePlayer()
    }
        
    func managerDidClipEnd() {
//        trackPreviewView.clip()
//        updatePlayer()
    }
}

extension EditorViewController {
    @IBAction private func clickPlay() {
        if self.player.status == .readyToPlay {
            debugPrint("ready for play")
            player.play()
        }
    }
    @IBAction private func clickClip() {
        let currentTime = self.player.currentTime()
        if let totalSeconds = editorManager.getTimeRange()?.duration.seconds {
            
            let progress = currentTime.seconds / totalSeconds
            trackPreviewView.split(at: progress)
        }
    }
    
    @IBAction private func clickInsertV1() {
        let path = Bundle.main.path(forResource: "insert.MOV", ofType: nil)!
        let asset = AVAsset(url: URL(fileURLWithPath: path))
        
        let currentTime = player.currentTime()
        do {
            try editorManager.insertTrack(asset, type: .video, at: currentTime)
            print("插入新的视频")
        }catch {
            print("插入新的视频出错: \(error)")
        }
    }
    @IBAction private func clickInsertV2WithPic() {
        let image = UIImage(named: "image_0")!
        [image].convertToVideos { (url) in
            let asset = AVAsset(url: url)
            let currentTime = self.player.currentTime()
            do {
                try self.editorManager.insertTrack(asset, type: .video, at: currentTime)
                print("插入新的视频图片合成视频")
            }catch {
                print("插入新的视频图片合成视频出错: \(error)")
            }
        }
        
    }
    @IBAction private func clickInsertOriginAudio() {
        do {
            try editorManager.insertTrack(editorManager.originAsset, type: .audio, at: .zero)
            print("插入原声音频")
        }catch {
            print("插入原声音频出错: \(error)")
        }
    }
    @IBAction private func clickRemoveV1() {
        
        
    }
    @IBAction private func clickRemoveV2() {
        
    }
    @IBAction private func clickRemoveOriginAudio() {
        
    }
}
