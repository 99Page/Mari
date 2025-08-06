//
//  ImagePlaceholderView.swift
//  Core
//
//  Created by 노우영 on 6/12/25.
//  Copyright © 2025 Page. All rights reserved.
//

import UIKit
import SwiftNavigation
import SnapKit
import SwiftUI

public class ImagePlaceholderView: UIView {
    
    private let gradientLayer = CAGradientLayer()
    private let placeholderView = UIView()
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        makeConstraint()
        setupShimmer()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    private func makeConstraint() {
        self.addSubview(placeholderView)
        
        self.placeholderView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
    
    private func setupShimmer() {
        backgroundColor = UIColor.systemGray5
        clipsToBounds = true

        // 그라데이션 레이어 색상 구성 (중앙이 밝고 양쪽이 어두운 형태)
        gradientLayer.colors = [
            UIColor.systemGray4.cgColor, // 어두운 회색
            UIColor.systemGray5.cgColor, // 밝은 회색 (하이라이트)
            UIColor.systemGray4.cgColor  // 어두운 회색
        ]
        
        // 색상 위치 지정 (가운데가 밝게 보이도록 설정)
        gradientLayer.locations = [0.0, 0.5, 1.0]
        
        // 그라데이션 시작 위치 (뷰의 왼쪽 위 바깥쪽)
        gradientLayer.startPoint = CGPoint(x: -1, y: 0)
        
        // 그라데이션 끝 위치 (뷰의 오른쪽 아래 바깥쪽)
        gradientLayer.endPoint = CGPoint(x: 1, y: 2)
        
        // 뷰의 레이어에 그라데이션 레이어 추가
        layer.addSublayer(gradientLayer)

        // 애니메이션 정의: 색상의 위치를 이동시켜 빛이 흘러가는 것처럼 보이게 함
        let animation = CABasicAnimation(keyPath: "locations")
        animation.fromValue = [-1.0, -0.5, 0.0]  // 시작 위치 (왼쪽 바깥)
        animation.toValue = [1.0, 1.5, 2.0]      // 끝 위치 (오른쪽 바깥)
        animation.duration = 1.5                // 애니메이션 지속 시간
        animation.repeatCount = .infinity       // 무한 반복
        
        // 애니메이션을 그라데이션 레이어에 적용
        gradientLayer.add(animation, forKey: "shimmer")
    }
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        gradientLayer.frame = bounds
    }
}

#Preview {
    ViewPreview(fromY: \.centerY, toY: \.centerY) {
        ImagePlaceholderView(frame: .zero)
    }
}
