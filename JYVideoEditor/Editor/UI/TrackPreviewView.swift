//
//  TrackPreviewView.swift
//  JYVideoEditor
//
//  Created by aha on 2021/2/19.
//

import UIKit
import AVFoundation
protocol TrackPreviewViewDelegate: class {
    func trackPreviewDidScroll(progress: Double)
}


class TrackPreviewView: UIView {
    
    weak var delegate: TrackPreviewViewDelegate?
    
    ///播放的进度
    var progress: Double = 0.0 {
        didSet {
            guard let videoTrackView = tracks.first, 0.0...1.0 ~= progress else {
                return
            }
            let trackWidth = videoTrackView.frame.width - videoTrackView.sideLineWidth * 2
            let contentOffsetX = -scrollView.contentInset.left + trackWidth * CGFloat(progress)
            scrollView.contentOffset = CGPoint(x: contentOffsetX, y: 0)
        }
    }
    
    ///目前所有插入的轨道
    var tracks: [TrackView] = []
    
    var manager: EditorManager!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }
    
    private var scrollView: UIScrollView!
    private var containerView: UIStackView!
}
extension TrackPreviewView {
    private func setupUI() {
        self.backgroundColor = .black
        
        //音视频轨道container
        let scrollView = UIScrollView()
        scrollView.backgroundColor = .black
        scrollView.delegate = self
        addSubview(scrollView)
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
        scrollView.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true
        scrollView.topAnchor.constraint(equalTo: topAnchor, constant: 30).isActive = true
        scrollView.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
        self.scrollView = scrollView
        
        let containerView = UIStackView()
        containerView.axis = .vertical
        containerView.spacing = 5
        containerView.alignment = .leading
        scrollView.addSubview(containerView)
        self.containerView = containerView
        containerView.translatesAutoresizingMaskIntoConstraints = false
        containerView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor).isActive = true
        containerView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor).isActive = true
        containerView.topAnchor.constraint(equalTo: scrollView.topAnchor).isActive = true
        containerView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor).isActive = true
        //添加占位图
//        containerView.addArrangedSubview(UIView())
        
        let centerIndicatorView = CenterIndicatorView()
        addSubview(centerIndicatorView)
        centerIndicatorView.translatesAutoresizingMaskIntoConstraints = false
        centerIndicatorView.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
        centerIndicatorView.topAnchor.constraint(equalTo: topAnchor).isActive = true
        centerIndicatorView.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
        centerIndicatorView.widthAnchor.constraint(equalToConstant: 2.0).isActive = true
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        if bounds != .zero {
            let width = bounds.width
            scrollView.contentInset = .init(top: 0, left: width/2 - 20 + 100, bottom: 0, right: width/2 - 20)
        }
    }
    
    func insertTrack(track: Track, progress: Double) {
//        if track.mediaType == .video,
//           let trackV = tracks.first,
//           let totalSeconds = manager.getTimeRange()?.duration.seconds,
//           let originImg = trackV.image,
//           let currentImg = track.previewImage {
//
//            let progress = track.insertTime.seconds / totalSeconds
//            let insertX = CGFloat(progress) * originImg.size.width
//
//            UIGraphicsBeginImageContextWithOptions(.init(width: originImg.size.width + currentImg.size.width, height: 50.0), false, 0)
//            guard let context = UIGraphicsGetCurrentContext() else {
//                return
//            }
//            defer { UIGraphicsEndImageContext() }
//            guard let originImgRef = originImg.cgImage else {return}
//            if let leftImgRef = originImgRef.cropping(to: .init(x: 0, y: 0, width: insertX * originImg.scale, height: 50.0 * originImg.scale)) {
//                let leftImgCroppingImg = UIImage(cgImage: leftImgRef, scale: originImg.scale, orientation: .up)
//                leftImgCroppingImg.draw(in: .init(x: 0, y: 0, width: insertX, height: 50.0))
//            }
//            if let rightImgRef = originImgRef.cropping(to: .init(x: insertX, y: 0, width: originImg.size.width * originImg.scale - insertX, height: 50.0 * originImg.scale)) {
//                let rightImgCroppingImg = UIImage(cgImage: rightImgRef, scale: originImg.scale, orientation: .up)
//                rightImgCroppingImg.draw(in: .init(x: insertX + currentImg.size.width, y: 0, width: originImg.size.width - insertX, height: 50.0))
//            }
//            if let currentImgRef = currentImg.cgImage {
//                context.draw(currentImgRef, in: .init(x: insertX, y: 0, width: currentImg.size.width, height: 50.0))
//            }
//            let resultImg = UIGraphicsGetImageFromCurrentImageContext()
//            trackV.image = resultImg
//            return
//        }
        
        let trackView = TrackView()
        containerView.addArrangedSubview(trackView)
        
        trackView.insertSubTrack(track: track, at: progress)
        tracks.append(trackView)

    }
    
    func split(at progress: Double) {
        tracks.first?.splitTrack(at: progress)
//        if let trackV = tracks.first,
//           let currentImg = trackV.image {
//            let currentClipRange = trackV.endProgress - trackV.startProgress
//            let clipX = currentImg.size.width * CGFloat(trackV.startProgress)
//            let width = currentImg.size.width * CGFloat(currentClipRange)
//            UIGraphicsBeginImageContextWithOptions(.init(width: width, height: 50.0), false, 0)
//            defer {
//                UIGraphicsEndImageContext()
//
//            }
//            if let imgRef = currentImg.cgImage?.cropping(to: .init(x: clipX, y: 0, width: width * currentImg.scale, height: 50.0 * currentImg.scale)) {
//                let imgCroppingImg = UIImage(cgImage: imgRef, scale: currentImg.scale, orientation: .up)
//                imgCroppingImg.draw(in: .init(x: 0, y: 0, width: width, height: 50.0))
//            }
//            let resultImg = UIGraphicsGetImageFromCurrentImageContext()
//
//            trackV.startProgress = 0.0
//            trackV.endProgress = 1.0
//            trackV.image = resultImg
//        }
    }
}

extension TrackPreviewView: UIScrollViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if scrollView.isTracking || scrollView.isDragging || scrollView.isDecelerating {
            guard let videoTrackView = tracks.first else {
                return
            }
            let trackWidth = videoTrackView.frame.width - videoTrackView.sideLineWidth * 2
            let progress = (scrollView.contentOffset.x + scrollView.contentInset.left) / trackWidth
            
            delegate?.trackPreviewDidScroll(progress: Double(progress))
        }
    }
}

