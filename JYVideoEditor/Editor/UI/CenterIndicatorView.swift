//
//  CenterIndicatorView.swift
//  JYVideoEditor
//
//  Created by aha on 2021/2/20.
//

import UIKit
class CenterIndicatorView: UIView {
    
    override func draw(_ rect: CGRect) {
        let indicatorLinePath =
            UIBezierPath(
                roundedRect: .init(
                    x: rect.width/2 - 1,
                    y: 0,
                    width: 2,
                    height: rect.height),
                byRoundingCorners: .allCorners,
                cornerRadii: .init(width: 1.0, height: 1.0)
            )
        UIColor.white.setFill()
        indicatorLinePath.fill()
    }
}
