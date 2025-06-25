//
//  LabelViewController.swift
//  CoreApp
//
//  Created by 노우영 on 6/12/25.
//

import Foundation
import UIKit
import SnapKit
import ComposableArchitecture
import Core

class LabelViewController: UIViewController {
    
    @UIBinding var labelState: RimLabel.State
    
    let label: RimLabel
    let textField = UITextField()
    
    init() {
        let background = UIView.Background(color: .systemBlue, cornerRadius: 16)
        let state = RimLabel.State(text: "Rim Label", textColor: .black, alignment: .center, background: background)
        @UIBinding var binding = state
        self.labelState = binding
        self.label = RimLabel(state: $binding)
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.addSubview(label)
        view.addSubview(textField)
        
        label.withKeyboardAvoid(height: 100) { make in
            make.centerX.centerY.equalToSuperview()
            make.width.height.equalTo(100)
        }
        
        label.configure()
        label.addAction(.touchUpInside({ debugPrint("label tapped") }))
        
        textField.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview()
            make.top.equalTo(label.snp.bottom).offset(20)
        }
        
        textField.placeholder = "placeholder"
    }
}
