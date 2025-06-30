//
//  ProgressViewController.swift
//  Core
//
//  Created by 노우영 on 6/30/25.
//  Copyright © 2025 Page. All rights reserved.
//

import Foundation
import UIKit
import ComposableArchitecture
import SnapKit
import SwiftUI


/// 전체 화면에 로딩 인디케이터를 표시하는 뷰 컨트롤러입니다.
///
/// 이 뷰는 화면 진입 직후가 아닌, 사용자의 추가적인 동작에 따른 로딩 상황에서 사용합니다.
/// 화면 진입 시 초기 로딩은 별도의 PlaceholderView를 사용하세요.
public class ProgressViewController: UIViewController {
    private let activityIndicator = UIActivityIndicatorView(style: .large)
    
    public init() {
        super.init(nibName: nil, bundle: nil)
        self.modalPresentationStyle = .overFullScreen
        self.modalTransitionStyle = .crossDissolve
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        makeConstraint()
        setupView()
    }
    
    private func setupView() {
        view.backgroundColor = .clear
        
        activityIndicator.color = UIColor(resource: .main)
        activityIndicator.startAnimating()
    }
    
    private func makeConstraint() {
        view.addSubview(activityIndicator)

        activityIndicator.snp.makeConstraints { make in
            make.width.height.equalTo(33)
            make.center.equalToSuperview()
        }
    }
}

@available(iOS 17.0, *)
#Preview {
    ViewControllerPreview {
        ProgressViewController()
    }
}
