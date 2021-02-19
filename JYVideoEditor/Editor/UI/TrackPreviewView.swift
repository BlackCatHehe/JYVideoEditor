//
//  TrackPreviewView.swift
//  JYVideoEditor
//
//  Created by aha on 2021/2/19.
//

import UIKit
import AVFoundation
class TrackPreviewView: UIView {
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }
    
    private var containerView: UIScrollView!
    
    override func draw(_ rect: CGRect) {
        let indicatorLinePath =
            UIBezierPath(
                roundedRect: .init(
                    x: rect.width/2 - 4.0,
                    y: 0,
                    width: 4.0,
                    height: rect.height),
                byRoundingCorners: .allCorners,
                cornerRadii: .init(width: 1.0, height: 1.0)
            )
        UIColor.white.setFill()
        indicatorLinePath.fill()
    }
}
extension TrackPreviewView {
    private func setupUI() {
        //音视频轨道container
        let scrollView = UIScrollView()
        scrollView.backgroundColor = .black
        addSubview(scrollView)
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
        scrollView.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true
        scrollView.topAnchor.constraint(equalTo: topAnchor).isActive = true
        scrollView.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
        self.containerView = scrollView
        
        layoutIfNeeded()
        let width = bounds.width
        scrollView.contentInset = .init(top: 0, left: width/2, bottom: 0, right: width/2)
    }
    
    func insertTrack(asset: AVAsset) {
        let trackView = TrackView()
        containerView.addSubview(trackView)
        trackView.translatesAutoresizingMaskIntoConstraints = false
        trackView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: bounds.width/2).isActive = true
        trackView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -bounds.width/2).isActive = true
        trackView.topAnchor.constraint(equalTo: containerView.topAnchor).isActive = true
        
        asset.generatePreviewImage(with: 1.0, caseSize: .init(width: 50.0, height: 50.0), result: { (img) in
            trackView.image = img
        })
    }
}
