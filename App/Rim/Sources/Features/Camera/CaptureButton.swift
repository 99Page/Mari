//
//  CaptureButton.swift
//  Rim
//
//  Created by 노우영 on 7/17/25.
//

import Foundation
import UIKit
import ComposableArchitecture
import Core
import SnapKit
import SwiftUI

class CaptureButton: UIView {
    private let outerCircle = UIView()
    private let innerCircle = UIView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }

    private func setupView() {
        addSubview(outerCircle)
        addSubview(innerCircle)
        
        // Outer circle (stroke)
        outerCircle.layer.borderColor = UIColor.white.cgColor
        outerCircle.layer.borderWidth = 4
        outerCircle.backgroundColor = .clear

        // Inner circle (filled)
        innerCircle.backgroundColor = .white

        // Layout with SnapKit
        outerCircle.snp.makeConstraints { make in
            make.edges.equalToSuperview()
            make.width.height.equalTo(64)
        }

        innerCircle.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.width.height.equalTo(50)
        }

        // Rounded corners
        outerCircle.layer.cornerRadius = 32
        innerCircle.layer.cornerRadius = 25
    }
}

#Preview {
    ViewPreview(fromY: \.centerY, toY: \.centerY) {
        CaptureButton()
    }
    .background {
        Color.black
    }
}
