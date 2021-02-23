//
//  TrackView.swift
//  JYVideoEditor
//
//  Created by aha on 2021/2/19.
//

import UIKit
@IBDesignable
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
    
    enum SideIndicator {
        case left
        case right
        case none
    }
    
    var currentMovingSide: SideIndicator = .none
    
    
    var startProgress: Double = 0.0 {
        didSet {
            
            startProgress = min(1.0, max(0.0, startProgress))

            if startProgress >= endProgress {
                startProgress = endProgress
            }
            setNeedsDisplay()
        }
    }
    var endProgress: Double = 1.0 {
        didSet {
            endProgress = min(1.0, max(0.0, endProgress))
            
            if endProgress <= startProgress {
                endProgress = startProgress
            }
            setNeedsDisplay()
        }
    }
    
    private var imageView: UIImageView!
    private var imgWidthAnchor: NSLayoutConstraint!
    private var imgHeightAnchor: NSLayoutConstraint!
    
    var image: UIImage? {
        didSet {
            if let image = image {
                if let widthConstraint = self.constraints.filter({ $0.firstAttribute == .width }).first,
                   let heightConstraint = self.constraints.filter({ $0.firstAttribute == .height }).first {
                    widthConstraint.constant = image.size.width + sideLineWidth * 2
                    heightConstraint.constant = image.size.height + lineHeight * 2
                    layoutIfNeeded()
                    setNeedsDisplay()
                    return
                }
                
                widthAnchor.constraint(equalToConstant: image.size.width + sideLineWidth * 2).isActive = true
                heightAnchor.constraint(equalToConstant: image.size.height + lineHeight * 2).isActive = true
                layoutIfNeeded()
                setNeedsDisplay()
            }
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }

    override func draw(_ rect: CGRect) {
        guard let context = UIGraphicsGetCurrentContext() else {
            return
        }
        context.clear(rect)
        
        if let image = self.image {
            image.draw(in: .init(x: sideLineWidth, y: lineHeight, width: image.size.width, height: image.size.height))
        }
        
        
        ///左侧进度指示器的minX
        let leftOriginMinX: CGFloat = (rect.width - sideLineWidth * 2) * CGFloat(startProgress)
        ///右侧进度指示器的minX
        let rightOriginMinX: CGFloat = sideLineWidth + (rect.width - sideLineWidth * 2) * CGFloat(endProgress)
        
        let leftSidePath = UIBezierPath(
            roundedRect: .init(x: leftOriginMinX ,
                               y: 0,
                               width: sideLineWidth,
                               height: rect.height),
            byRoundingCorners: [.topLeft, .bottomLeft],
            cornerRadii: .init(width: sideCornerRadius, height: sideCornerRadius))
        
        ///左侧进度指示器孔的minX
        let leftCenterLineMinX = leftOriginMinX + 9.0
        
        let leftCenterLinePath = UIBezierPath(
            roundedRect:  .init(x: leftCenterLineMinX,
                                y: rect.height / 2 - sideCenterLineHeight/2,
                                width: sideCenterLineWidth,
                                height: sideCenterLineHeight),
            cornerRadius: sideCenterLineCornerRadius
        )
     
        let rightSidePath = UIBezierPath(
            roundedRect: .init(
                x: rightOriginMinX,
                y: 0,
                width: sideLineWidth,
                height: rect.height
            ),
            byRoundingCorners: [.topRight, .bottomRight],
            cornerRadii: .init(width: sideCornerRadius, height: sideCornerRadius)
        )
        
        ///右侧进度指示器孔的minX
        let rightCenterLineMinX = rightOriginMinX + 9.0
        let rightCenterLinePath = UIBezierPath(
            roundedRect: .init(
                x: rightCenterLineMinX,
                y: rect.height / 2 - sideCenterLineHeight/2,
                width: sideCenterLineWidth,
                height: sideCenterLineHeight
            ),
            cornerRadius: sideCenterLineCornerRadius
        )
        
        ///上下线条的minX
        let lineMinX = leftOriginMinX + sideLineWidth
        ///上下线条的宽度
        let lineWidth: CGFloat = rightOriginMinX - lineMinX
        
        let topLinePath = UIBezierPath(
            rect: .init(
                x: lineMinX,
                y: 0,
                width: lineWidth,
                height: lineHeight)
        )
        let bottomLinePath = UIBezierPath(
            rect: .init(
                x: lineMinX,
                y: rect.height - lineHeight,
                width: lineWidth,
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
        addGestureRecognizer(pan)
    }
    
    @objc private func panValueChanged(_ pan: UIPanGestureRecognizer) {
        let currentX = pan.location(in: self).x
        
        let progress = Double((currentX - sideLineWidth) / (bounds.width - sideLineWidth * 2))
        if pan.state == .changed {
            switch currentMovingSide {
            case .left:
                startProgress = progress
            case .right:
                endProgress = progress
            default:
                break
            }
        }
        
        if pan.state == .cancelled, pan.state == .failed, pan.state == .ended {
            currentMovingSide = .none
        }
    }
}

extension TrackView {
    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        guard super.point(inside: point, with: event) == true else {
            return false
        }
        ///左侧进度指示器的minX
        let leftOriginMinX: CGFloat = (bounds.width - sideLineWidth * 2) * CGFloat(startProgress)
        ///右侧进度指示器的minX
        let rightOriginMinX: CGFloat = sideLineWidth + (bounds.width - sideLineWidth * 2) * CGFloat(endProgress)
        
        let leftSideBounds = CGRect.init(
            x: leftOriginMinX,
            y: 0,
            width: sideLineWidth,
            height: bounds.height)
        debugPrint("leftSideBounds: \(leftSideBounds)")
        if leftSideBounds.contains(point) {
            debugPrint("belong left")
            currentMovingSide = .left
            return true
        }
        
        let rightSideBounds = CGRect.init(
            x: rightOriginMinX,
            y: 0,
            width: sideLineWidth,
            height: bounds.height)
        debugPrint("rightSideBounds: \(rightSideBounds)")
        if rightSideBounds.contains(point) {
            currentMovingSide = .right
            debugPrint("belong right")
            return true
        }
        currentMovingSide = .none
        return false
    }
}
