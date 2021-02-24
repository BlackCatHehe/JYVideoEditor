//
//  TrackView.swift
//  JYVideoEditor
//
//  Created by aha on 2021/2/19.
//

import UIKit
@IBDesignable

class SubTrack {
    enum MovingSide {
        case left
        case right
        case none
    }
    
    var image: UIImage
    var startProgress: Double = 0.0
    var endProgress: Double = 1.0
    var isSelected: Bool = false
    
    var moveingSide: MovingSide = .none
    var movingStartPoint: CGPoint = .zero
    
    var currentWidth: CGFloat {
        image.size.width * CGFloat(endProgress - startProgress)
    }
    var showRectForBounds: CGRect {
        let x = image.size.width * CGFloat(startProgress)
        return CGRect(x: x, y: 0, width: currentWidth, height: image.size.height)
    }
    
    ///在视图中绘制的位置,在绘制后更新
    var frame: CGRect?
    
    init(image: UIImage) {
        self.image = image
    }
}


class TrackView: UIView {
    
    ///两侧进度指示器的宽度
    var sideLineWidth: CGFloat = 20.0
    ///两侧进度指示器的圆角
    var sideCornerRadius: CGFloat = 3.0
    ///两侧进度指示器中间孔的宽
    var sideCenterLineHeight: CGFloat = 8.0
    ///两侧进度指示器中间孔的高
    var sideCenterLineWidth: CGFloat = 2.0
    ///两侧进度指示器中间孔的圆角
    var sideCenterLineCornerRadius: CGFloat {
        sideCenterLineWidth / 2.0
    }
    ///上下线条的高度
    var lineHeight: CGFloat = 2.0
    
    
    private var imageView: UIImageView!
    private var imgWidthAnchor: NSLayoutConstraint!
    private var imgHeightAnchor: NSLayoutConstraint!
    
    var splitLocations: [CGFloat] = [0, 0]
    var subTracks: [SubTrack] = []
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }
    
    
    func splitTrack(at progress: Double) {
        let splitPosition = (self.bounds.width - sideLineWidth * 2) * CGFloat(progress) + sideLineWidth
        splitTrack(at: CGPoint(x: splitPosition, y: bounds.height/2))
    }
    
    func splitTrack(at point: CGPoint) {
        splitLocations.append(point.x)
        splitLocations.sort()
        
        //定位到被裁剪的track
        guard let trackIndex = subTracks.firstIndex(where: { ($0.frame ?? .zero).contains(point) }) else {
            return
        }
        let track = subTracks[trackIndex]
        
        let trackMinX = track.frame!.minX
        let splitPointDistanceFromTrackOriginMinX = point.x - trackMinX + track.image.size.width * CGFloat(track.startProgress)
        let splitProgress = splitPointDistanceFromTrackOriginMinX / track.image.size.width
        
        let leftSplitTrack = SubTrack(image: track.image)
        leftSplitTrack.startProgress = track.startProgress
        leftSplitTrack.endProgress = Double(splitProgress)
        
        let rightSplitTrack = SubTrack(image: track.image)
        rightSplitTrack.startProgress = Double(splitProgress)
        rightSplitTrack.endProgress = track.endProgress
        
        subTracks.remove(at: trackIndex)
        subTracks.insert(leftSplitTrack, at: trackIndex)
        subTracks.insert(rightSplitTrack, at: trackIndex + 1)
        
        setNeedsDisplay()
    }
    
    func insertSubTrack(track: Track, at currentIndicatorProgress: Double) {
        let insertPosition = (self.bounds.width - sideLineWidth * 2) * CGFloat(currentIndicatorProgress) - sideLineWidth
        insertSubTrack(track: track, at: .init(x: insertPosition, y: bounds.height/2))
    }
    func insertSubTrack(track: Track, at currentIndicatorPoint: CGPoint) {
        //定位到被裁剪的track
        guard let subTrackIndex = subTracks.firstIndex(where: { ($0.frame ?? .zero).contains(currentIndicatorPoint) }) else {
            let subTrack = SubTrack(image: track.previewImage!)
            subTracks.append(subTrack)
            updateInternalSize()
            return
        }
        let subTrack = subTracks[subTrackIndex]
        let subTrackFrame = subTrack.frame!
        let insertSubTrack = SubTrack(image: track.previewImage!)
        if (currentIndicatorPoint.x - subTrackFrame.minX) <= (subTrackFrame.maxX - currentIndicatorPoint.x) {
            subTracks.insert(insertSubTrack, at: subTrackIndex)
        }else {
            subTracks.insert(insertSubTrack, at: subTrackIndex + 1)
        }
        updateInternalSize()
        
    }
    
    func updateInternalSize() {
        if subTracks.isEmpty { return }
        let width = subTracks.reduce(into: CGFloat(0)) { (result, subTrack) in
            result += subTrack.currentWidth
        }
        
        if let widthConstraint = self.constraints.filter({ $0.firstAttribute == .width }).first {
            widthConstraint.constant = width + sideLineWidth * 2
        }else {
            widthAnchor.constraint(equalToConstant: width + sideLineWidth * 2).isActive = true
            heightAnchor.constraint(equalToConstant: subTracks.first!.image.size.height + lineHeight * 2).isActive = true
        }
        splitLocations[0] = sideLineWidth
        splitLocations[splitLocations.count - 1] = width + sideLineWidth
        layoutIfNeeded()
        setNeedsDisplay()
        
    }

    override func draw(_ rect: CGRect) {
        guard let context = UIGraphicsGetCurrentContext() else {
            return
        }
        context.clear(rect)
        
        func drawImage(for track: SubTrack, at leftX: CGFloat) -> CGFloat {
            let image = track.image
            if let imageRef = image.cgImage,
               let clipImageRef = imageRef.cropping(to: track.showRectForBounds.applying(.init(scaleX: image.scale, y: image.scale)))
               {
                let resultImg = UIImage(cgImage: clipImageRef, scale: image.scale, orientation: .up)
                let frame = CGRect(x: leftX, y: lineHeight, width: track.currentWidth, height: image.size.height)
                resultImg.draw(in: frame)
                track.frame = frame
                return leftX + track.currentWidth
            }
            return 0
        }
        
        _ = subTracks.reduce(into: sideLineWidth) { (resultLeftX, subTrack) in
            resultLeftX = drawImage(for: subTrack, at: resultLeftX)
        }
        subTracks.forEach { (subTrack) in
            drawSelectBorder(track: subTrack)
        }
        
        UIColor.cyan.setFill()
        for i in splitLocations.dropFirst().dropLast() {
            let radius: CGFloat = 8
            let topPoint = CGPoint(x: i, y: rect.height / 2 - radius)
            let leftPoint = CGPoint(x: i - radius, y: rect.height / 2)
            let bottomPoint = CGPoint(x: i, y: rect.height / 2 + radius)
            let rightPoint = CGPoint(x: i + radius, y: rect.height / 2)
            
            let splitPath = UIBezierPath()
            splitPath.move(to: topPoint)
            splitPath.addLine(to: leftPoint)
            splitPath.addLine(to: bottomPoint)
            splitPath.addLine(to: rightPoint)
            splitPath.close()
            
            splitPath.fill()
        }
    }
    
    func drawSelectBorder(track: SubTrack) {
        if !track.isSelected { return }
        
        let rect = (track.frame ?? .zero).insetBy(dx: -sideLineWidth, dy: -lineHeight)

        let leftMinX = rect.minX
        let leftSidePath = UIBezierPath(
            roundedRect: .init(x: leftMinX,
                               y: 0,
                               width: sideLineWidth,
                               height: rect.height),
            byRoundingCorners: [.topLeft, .bottomLeft],
            cornerRadii: .init(width: sideCornerRadius, height: sideCornerRadius))
        
        ///左侧进度指示器孔的minX
        let leftCenterLineMinX = leftMinX + (sideLineWidth - sideCenterLineWidth)/2
        
        let leftCenterLinePath = UIBezierPath(
            roundedRect:  .init(x: leftCenterLineMinX,
                                y: rect.height / 2 - sideCenterLineHeight/2,
                                width: sideCenterLineWidth,
                                height: sideCenterLineHeight),
            cornerRadius: sideCenterLineCornerRadius
        )
        
        let rightMinX = rect.maxX - sideLineWidth
        let rightSidePath = UIBezierPath(
            roundedRect: .init(
                x: rightMinX,
                y: 0,
                width: sideLineWidth,
                height: rect.height
            ),
            byRoundingCorners: [.topRight, .bottomRight],
            cornerRadii: .init(width: sideCornerRadius, height: sideCornerRadius)
        )
        
        ///右侧进度指示器孔的minX
        let rightCenterLineMinX = rightMinX + (sideLineWidth - sideCenterLineWidth)/2
        let rightCenterLinePath = UIBezierPath(
            roundedRect: .init(
                x: rightCenterLineMinX,
                y: rect.height / 2 - sideCenterLineHeight/2,
                width: sideCenterLineWidth,
                height: sideCenterLineHeight
            ),
            cornerRadius: sideCenterLineCornerRadius
        )
        
        let topLinePath = UIBezierPath(
            rect: .init(
                x: leftMinX + sideLineWidth,
                y: 0,
                width: rect.width - sideLineWidth * 2,
                height: lineHeight)
        )
        let bottomLinePath = UIBezierPath(
            rect: .init(
                x: leftMinX + sideLineWidth,
                y: rect.height - lineHeight,
                width: rect.width - sideLineWidth * 2,
                height: lineHeight)
        )
        
        UIColor.white.setFill()
        leftSidePath.fill()
        rightSidePath.fill()
        topLinePath.fill()
        bottomLinePath.fill()
        
        UIColor.gray.setFill()
        leftCenterLinePath.fill()
        rightCenterLinePath.fill()
    }
}

extension TrackView {
    private func setupUI() {
    
        let pan = UIPanGestureRecognizer(target: self, action: #selector(panValueChanged(_:)))
        pan.maximumNumberOfTouches = 1
        pan.delegate = self
        addGestureRecognizer(pan)
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(tap(_:)))
        addGestureRecognizer(tap)
    }
    
    @objc private func tap(_ tap: UITapGestureRecognizer) {
        let tapPoint = tap.location(in: self)
        
        
        subTracks.forEach { (subTrack) in
            if (subTrack.frame ?? .zero).contains(tapPoint) {
                subTrack.isSelected.toggle()
            }else {
                subTrack.isSelected = false
            }
        }
        setNeedsDisplay()
        
    }
    
    @objc private func panValueChanged(_ pan: UIPanGestureRecognizer) {
        let panPoint = pan.location(in: self)
        
        guard let subTrack = subTracks.first(where: { $0.isSelected == true }) else {
            return
        }
        if pan.state == .began {
            subTrack.movingStartPoint = panPoint
            if (panPoint.x - subTrack.frame!.maxX) < 0 {
                subTrack.moveingSide = .left
            }else {
                subTrack.moveingSide = .right
            }
        }
        if pan.state == .changed {
            print(panPoint.x, subTrack.movingStartPoint.x)
            let currentOffset = panPoint.x - subTrack.movingStartPoint.x
            let offsetProgress = Double(currentOffset / subTrack.image.size.width)
            
            switch subTrack.moveingSide {
            case .left:
                subTrack.startProgress += offsetProgress
            case .right:
                subTrack.endProgress += offsetProgress
            default:
                break
            }
            updateInternalSize()
            
            subTrack.movingStartPoint = panPoint
        }
        
        if pan.state == .cancelled, pan.state == .failed, pan.state == .ended {
            subTrack.moveingSide = .none
            subTrack.movingStartPoint = .zero
        }
    }
}

extension TrackView: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRequireFailureOf otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        let touchPoint = gestureRecognizer.location(in: gestureRecognizer.view)
        if let subTrack = subTracks.first(where: { ($0.frame ?? .zero).insetBy(dx: -sideLineWidth, dy: -lineHeight).contains(touchPoint) }) {
            let leftSideBounds = CGRect(x: subTrack.frame!.minX - sideLineWidth, y: 0, width: sideLineWidth, height: subTrack.frame!.height)
            let rightSideBounds = CGRect(x: subTrack.frame!.maxX - sideLineWidth, y: 0, width: sideLineWidth, height: subTrack.frame!.height)
            if leftSideBounds.contains(touchPoint) || rightSideBounds.contains(touchPoint) {
                return false
            }
        }
        return true
    }
}

extension TrackView {
    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        guard super.point(inside: point, with: event) == true else {
            return false
        }
        return true
        
//        ///左侧进度指示器的minX
//        let leftOriginMinX: CGFloat = (bounds.width - sideLineWidth * 2) * CGFloat(startProgress)
//        ///右侧进度指示器的minX
//        let rightOriginMinX: CGFloat = sideLineWidth + (bounds.width - sideLineWidth * 2) * CGFloat(endProgress)
//
//        let leftSideBounds = CGRect.init(
//            x: leftOriginMinX,
//            y: 0,
//            width: sideLineWidth,
//            height: bounds.height)
//        debugPrint("leftSideBounds: \(leftSideBounds)")
//        if leftSideBounds.contains(point) {
//            debugPrint("belong left")
//            currentMovingSide = .left
//            return true
//        }
//
//        let rightSideBounds = CGRect.init(
//            x: rightOriginMinX,
//            y: 0,
//            width: sideLineWidth,
//            height: bounds.height)
//        debugPrint("rightSideBounds: \(rightSideBounds)")
//        if rightSideBounds.contains(point) {
//            currentMovingSide = .right
//            debugPrint("belong right")
//            return true
//        }
//        currentMovingSide = .none
//
//        subTracks.forEach { (subTrack) in
////            subTrack.isSelected = subTrack.currentFrame(with: bounds).contains(point)
//        }
//        setNeedsDisplay()
        
        return false
    }
}
