//
//  UIView + addAction.swift
//  Core
//
//  Created by 노우영 on 6/12/25.
//  Copyright © 2025 Page. All rights reserved.
//

import Foundation
import UIKit

public enum UIViewAction {
    case touchUpInside(() -> Void)
}

// AssociatedKeys 구조체는 연관 객체 키를 저장하는 용도로 사용됨
private struct AssociatedKeys {
    // touchUpInside 동작에 대한 연관 키를 UInt8 타입으로 정의
    static var touchUpInsideKey: UInt8 = 0
}

public extension UIView {
    /// UIView에 특정 액션을 추가
    func addAction(_ action: UIViewAction) {
        isUserInteractionEnabled = true

        switch action {
        case .touchUpInside(let handler):
            let trackingView = TouchInsideTrackingView()
            trackingView.action = handler
            trackingView.translatesAutoresizingMaskIntoConstraints = false
            trackingView.backgroundColor = .clear
            trackingView.isUserInteractionEnabled = true

            addSubview(trackingView)
            NSLayoutConstraint.activate([
                trackingView.topAnchor.constraint(equalTo: topAnchor),
                trackingView.bottomAnchor.constraint(equalTo: bottomAnchor),
                trackingView.leadingAnchor.constraint(equalTo: leadingAnchor),
                trackingView.trailingAnchor.constraint(equalTo: trailingAnchor),
            ])
        }
    }
}

// 내부용 터치 추적 클래스 정의
private final class TouchInsideTrackingView: UIView {
    var action: (() -> Void)?
    private var isTouchInside = false

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        isTouchInside = true
        animateTouchDown()
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let point = touches.first?.location(in: self) {
            let inside = bounds.contains(point)
            if isTouchInside != inside {
                isTouchInside = inside
                inside ? animateTouchDown() : animateTouchUp()
            }
        }
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        animateTouchUp()
        if isTouchInside {
            action?()
        }
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        isTouchInside = false
        animateTouchUp()
    }

    private func animateTouchDown() {
        UIView.animate(withDuration: 0.3) {
            self.superview?.transform = CGAffineTransform(scaleX: 0.96, y: 0.96)
            self.superview?.alpha = 0.8
        }
    }

    private func animateTouchUp() {
        UIView.animate(withDuration: 0.3) {
            self.superview?.transform = .identity
            self.superview?.alpha = 1.0
        }
    }
}
