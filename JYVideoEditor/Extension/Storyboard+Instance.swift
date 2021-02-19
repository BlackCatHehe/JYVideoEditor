//
//  Storyboard+Instance.swift
//  JYVideoEditor
//
//  Created by aha on 2021/2/19.
//

import UIKit
extension UIViewController {
    static func loadInstanceFromSB(storyboard name: String = "Main", identifier: String? = nil) -> UIViewController {
        return UIStoryboard.init(name: name, bundle: .main).instantiateViewController(withIdentifier: identifier ?? String(describing: self))
    }
}
