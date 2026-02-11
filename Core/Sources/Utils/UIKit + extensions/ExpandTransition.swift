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
        return 1
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
            animatePresentation(
                using: transitionContext,
                containerView: containerView,
                toVC: toVC,
                fromVC: fromVC,
                toView: toView,
                sourceRect: sourceRect
            )
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
    
    private func animatePresentation(
        using transitionContext: UIViewControllerContextTransitioning,
        containerView: UIView,
        toVC: UIViewController,
        fromVC: UIViewController?,
        toView: UIView,
        sourceRect: CGRect
    ) {
        let finalFrame = transitionContext.finalFrame(for: toVC)
        
        // 1. 비율 정의 (W:H 기준)
        let imageRatio: CGFloat = 5 / 4    // 1.25 (Portrait)
        let targetMaskRatio: CGFloat = 7 / 9 // 0.77 (Landscape)
        
        // 2. 높이 계산
        let imageHeight = finalFrame.width * imageRatio // 4:5 전체 이미지 높이
        let maskHeight = finalFrame.width * targetMaskRatio // 9:7 마스크 높이
        
        // 3. [핵심] 중앙 정렬을 위한 마스크 Y 오프셋 계산
        // 전체 이미지 높이에서 마스크 높이를 뺀 값의 절반만큼 아래로 내립니다.
        // 이렇게 해야 위아래가 똑같은 비율로 잘립니다.
        let maskTopOffset = (imageHeight - maskHeight) / 2
        
        // 4. toView 초기 설정
        toView.frame = finalFrame
        toView.clipsToBounds = false
        containerView.addSubview(toView)
        toView.layoutIfNeeded()
        
        // 5. 파란색 가이드 뷰 (이미지 중앙의 9:7 영역)
        // y 위치를 maskTopOffset으로 설정하여 중앙에 배치합니다.
        let blueOverlay = UIView(frame: CGRect(x: 0, y: maskTopOffset, width: finalFrame.width, height: maskHeight))
        blueOverlay.backgroundColor = UIColor.blue
        blueOverlay.layer.borderWidth = 2
        blueOverlay.layer.borderColor = UIColor.blue.cgColor
        toView.addSubview(blueOverlay)
        toView.mask = blueOverlay
        
        // 6. 축소 비율(Scale) 계산
        let scaleX = sourceRect.width / finalFrame.width
        let scaleY = sourceRect.height / maskHeight
        
        // 7. Transform 적용
        toView.transform = CGAffineTransform(scaleX: scaleX, y: scaleY)
        
        // 8. [중요] 좌표 보정 (중앙 정렬된 파란색 영역을 마커에 맞춤)
        let maskCenterYInToView = maskTopOffset + (maskHeight / 2)
        let scaledMaskCenterY = maskCenterYInToView * scaleY
        
        // 전체 뷰의 중심점(scaledFullHeight / 2)과 마스크 중심점의 차이만큼 이동
        let scaledFullHeight = finalFrame.height * scaleY
        let centerYOffset = (scaledFullHeight / 2) - scaledMaskCenterY
        
        toView.center = CGPoint(
            x: sourceRect.midX,
            y: sourceRect.midY + centerYOffset
        )
        
        UIView.animate(withDuration: transitionDuration(using: transitionContext),
                       delay: 0,
                       usingSpringWithDamping: 0.8,
                       initialSpringVelocity: 0,
                       options: .curveEaseOut) {
            
            toView.transform = .identity
            toView.center = CGPoint(x: finalFrame.midX, y: finalFrame.midY)
            
            blueOverlay.frame = CGRect(origin: .zero, size: finalFrame.size)
            
            toView.layer.cornerRadius = 0
            toView.layoutIfNeeded()
        } completion: { _ in
            // 가이드 뷰 제거 및 전환 완료 보고
            blueOverlay.removeFromSuperview()
            transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
        }
    }
}
