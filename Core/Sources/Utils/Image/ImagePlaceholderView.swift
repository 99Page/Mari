//
//  ImagePlaceholderView.swift
//  Core
//
//  Created by 노우영 on 6/12/25.
//  Copyright © 2025 Page. All rights reserved.
//

import UIKit
import ComposableArchitecture
import SnapKit
import SwiftUI

public class ImagePlaceholderView: UIView, Previewable {
    private let gradientLayer = CAGradientLayer()
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    public func configure() {
        makeConstraint()
        setupShimmer()
    }
    
    private func makeConstraint() {
        self.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
    
    
    private func setupShimmer() {
        backgroundColor = UIColor.systemGray5
        clipsToBounds = true
        
        gradientLayer.colors = [
            UIColor.systemGray4.cgColor,
            UIColor.systemGray5.cgColor,
            UIColor.systemGray4.cgColor
        ]
        gradientLayer.locations = [0.0, 0.5, 1.0]
        gradientLayer.startPoint = CGPoint(x: -1, y: 0) // Diagonal start (top-left)
        gradientLayer.endPoint = CGPoint(x: 1, y: 2)     // Diagonal end (bottom-right)
        layer.addSublayer(gradientLayer)
        
        let animation = CABasicAnimation(keyPath: "locations")
        animation.fromValue = [-1.0, -0.5, 0.0]
        animation.toValue = [1.0, 1.5, 2.0]
        animation.duration = 1.5
        animation.repeatCount = .infinity
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
