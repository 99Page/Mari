//
//  ExpandTransition.swift
//  Core
//
//  Created by 노우영 on 2/10/26.
//  Copyright © 2026 Page. All rights reserved.
//

import UIKit

public protocol ExpandTransitionSourceDelegate: AnyObject {
    func transitionSourceRect() -> CGRect?
}

final public  class ExpandAnimator: NSObject, UIViewControllerAnimatedTransitioning {
    
    public let isPresenting: Bool
    
    public init(isPresenting: Bool) {
        self.isPresenting = isPresenting
        super.init()
    }
    
    public func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return 0.6
    }
    
    public func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        // 1. 필요한 객체 가져오기
        guard let toVC = transitionContext.viewController(forKey: .to),
              let fromVC = transitionContext.viewController(forKey: .from),
              let toView = transitionContext.view(forKey: .to),
              let fromView = transitionContext.view(forKey: .from) else {
            transitionContext.completeTransition(false)
            return
        }
        
        let containerView = transitionContext.containerView
        
        // 2. Source Delegate 찾기 (마커 위치를 알아야 함)
        // Present할 땐 fromVC(Map)가 소스, Dismiss할 땐 toVC(Map)가 소스
        let sourceDelegate = (isPresenting ? fromVC : toVC) as? ExpandTransitionSourceDelegate
        
        guard let sourceRect = sourceDelegate?.transitionSourceRect() else {
            transitionContext.completeTransition(false)
            return
        }
        
        // 3. 애니메이션 준비
        if isPresenting {
            // [Push: 지도 -> 리스트]
            containerView.addSubview(toView)
            
            // A. 최종 화면 크기
            let finalFrame = transitionContext.finalFrame(for: toVC)
            toView.frame = finalFrame
            toView.layoutIfNeeded() // 레이아웃을 미리 잡아서 내부 이미지 위치 확정
            
            // B. 변환 계산 (전체 화면을 마커 크기만큼 축소하려면 얼만큼 줄여야 하는가?)
            let scaleX = sourceRect.width / finalFrame.width
            let scaleY = sourceRect.height / finalFrame.height
            
            // C. 초기 상태 설정 (마커 위치로 축소 & 이동)
            let transform = CGAffineTransform(scaleX: scaleX, y: scaleY)
            toView.transform = transform
            toView.center = CGPoint(x: sourceRect.midX, y: sourceRect.midY)
            toView.layer.masksToBounds = true
            toView.layer.cornerRadius = 20 // 마커처럼 둥글게 시작
            
            // D. 애니메이션 실행 (펴지기)
            UIView.animate(withDuration: transitionDuration(using: transitionContext),
                           delay: 0,
                           usingSpringWithDamping: 0.75, // 튕기는 맛 추가
                           initialSpringVelocity: 0,
                           options: .curveEaseOut) {
                
                toView.transform = .identity // 원래 크기로 복귀
                toView.center = CGPoint(x: finalFrame.midX, y: finalFrame.midY) // 원래 위치로 복귀
                toView.layer.cornerRadius = 0 // 둥근 모서리 제거
                
            } completion: { _ in
                transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
            }
            
        } else {
            // [Pop: 리스트 -> 지도]
            // 반대로 리스트가 마커 위치로 작아지면서 사라짐
            containerView.insertSubview(toView, belowSubview: fromView) // 지도를 밑에 깔아둠
            
            let finalFrame = fromView.frame
            let scaleX = sourceRect.width / finalFrame.width
            let scaleY = sourceRect.height / finalFrame.height
            
            UIView.animate(withDuration: transitionDuration(using: transitionContext),
                           delay: 0,
                           usingSpringWithDamping: 0.8,
                           initialSpringVelocity: 0,
                           options: .curveEaseInOut) {
                
                // 마커 위치로 축소 & 이동
                let transform = CGAffineTransform(scaleX: scaleX, y: scaleY)
                fromView.transform = transform
                fromView.center = CGPoint(x: sourceRect.midX, y: sourceRect.midY)
                fromView.layer.cornerRadius = 20
                
            } completion: { _ in
                transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
            }
        }
    }
}
