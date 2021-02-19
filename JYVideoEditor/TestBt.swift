//
//  TestBt.swift
//  JYVideoEditor
//
//  Created by aha on 2021/2/19.
//

import UIKit
class TestBt: UIButton {
    
    
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        let v = super.hitTest(point, with: event)
        print("\(title(for: .normal)) hitTest: \(v)")
        return v
    }
    
    
    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        let bo = super.point(inside: point, with: event)
        print("\(title(for: .normal)) point inside: \(bo)")
        return bo
        
        
    }
    
    
}

class TestView: UIView {
    
    @IBInspectable var title: String? = nil
    
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        let v = super.hitTest(point, with: event)
        print("\(title) hitTest: \(v)")
        return v
    }
    
    
    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        let bo = super.point(inside: point, with: event)
        print("\(title) point inside: \(bo)")
        return bo
        
        
    }
    
    
}
