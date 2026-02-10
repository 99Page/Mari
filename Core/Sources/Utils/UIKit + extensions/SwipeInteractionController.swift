//
//  SwipeInteractionController.swift
//  Core
//
//  Created by 노우영 on 2/11/26.
//  Copyright © 2026 Page. All rights reserved.
//

import Foundation
import UIKit

public class SwipeInteractionController: UIPercentDrivenInteractiveTransition {
    
    public var interactionInProgress = false
    private var shouldCompleteTransition = false
    private weak var viewController: UIViewController?
    
    public init(viewController: UIViewController) {
        super.init()
        self.viewController = viewController
        prepareGestureRecognizer(in: viewController.view)
    }
    
    private func prepareGestureRecognizer(in view: UIView) {
        // 화면 왼쪽 가장자리 스와이프 감지
        let gesture = UIScreenEdgePanGestureRecognizer(target: self, action: #selector(handleGesture(_:)))
        gesture.edges = .left
        view.addGestureRecognizer(gesture)
    }
    
    @objc public func handleGesture(_ gestureRecognizer: UIScreenEdgePanGestureRecognizer) {
        guard let view = gestureRecognizer.view?.superview else { return }
        
        // 이동 거리 계산 (화면 너비 기준)
        let translation = gestureRecognizer.translation(in: view)
        var progress = (translation.x / view.bounds.width)
        progress = CGFloat(fminf(fmaxf(Float(progress), 0.0), 1.0))
        
        switch gestureRecognizer.state {
        case .began:
            interactionInProgress = true
            // ⭐️ 여기서 pop을 호출하면 네비게이션 컨트롤러가 애니메이션을 시작함
            viewController?.navigationController?.popViewController(animated: true)
            
        case .changed:
            shouldCompleteTransition = progress > 0.3 // 30% 이상 이동하면 완료 처리
            update(progress) // 애니메이션 진행률 업데이트
            
        case .cancelled:
            interactionInProgress = false
            cancel() // 취소하면 다시 원래 화면으로 돌아감
            
        case .ended:
            interactionInProgress = false
            if shouldCompleteTransition {
                finish() // 완료하면 지도 화면으로 넘어감
            } else {
                cancel()
            }
            
        default:
            break
        }
    }
}
