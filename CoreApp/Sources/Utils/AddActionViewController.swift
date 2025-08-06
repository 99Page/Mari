//
//  AddActionViewController.swift
//  CoreApp
//
//  Created by 노우영 on 6/12/25.
//

import Foundation
import UIKit
import SnapKit
import Core

class AddActionViewController: UIViewController {
    let label = UILabel(frame: .zero)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.addSubview(label)
        
        label.snp.makeConstraints { make in
            make.centerX.centerY.equalToSuperview()
            make.width.height.equalTo(100)
        }
        
        label.text = "Label"
        label.backgroundColor = .systemBlue
        label.textColor = .white
        label.addAction(.touchUpInside(print))
    }
    
    private func print() {
        debugPrint("tapped")
    }
}
