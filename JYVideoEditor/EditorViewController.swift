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
        let playerVC = AVPlayerViewController()
        playerVC.player = AVPlayer(url: URL(fileURLWithPath: sourcePath))
        self.player = playerVC.player
        addChild(playerVC)
        playerView.addSubview(playerVC.view)
        playerVC.view.translatesAutoresizingMaskIntoConstraints = false
        playerVC.view.leadingAnchor.constraint(equalTo: playerView.leadingAnchor).isActive = true
        playerVC.view.trailingAnchor.constraint(equalTo: playerView.trailingAnchor).isActive = true
        playerVC.view.topAnchor.constraint(equalTo: playerView.topAnchor).isActive = true
        playerVC.view.bottomAnchor.constraint(equalTo: playerView.bottomAnchor).isActive = true
        
        
        let asset = AVAsset(url: URL(fileURLWithPath: sourcePath))
        trackPreviewView.insertTrack(asset: asset)
    }
}

extension EditorViewController {
    @IBAction private func clickPlay() {
        if self.player.status == .readyToPlay {
            debugPrint("ready for play")
            player.play()
        }
    }
}
