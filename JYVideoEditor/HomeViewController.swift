//
//  HomeViewController.swift
//  JYVideoEditor
//
//  Created by aha on 2021/2/19.
//

import Foundation
import UIKit
class HomeViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
    }
    
    @IBAction func clickChooseVideo(_ sender: UIButton) {
        let sourcePath = Bundle.main.path(forResource: "source.mp4", ofType: nil)!
        
        let editorVC = EditorViewController.instance(sourcePath: sourcePath)
        navigationController?.pushViewController(editorVC, animated: true)
  
    }
}
