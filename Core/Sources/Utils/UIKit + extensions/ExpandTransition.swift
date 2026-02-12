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
    func transitionInitialCornerRadius() -> CGFloat
}

public extension ExpandTransitionSourceDelegate {
    func transitionInitialCornerRadius() -> CGFloat { 0 }
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
            animatePresentation(
                using: transitionContext,
                containerView: containerView,
                toVC: toVC,
                fromVC: fromVC,
                toView: toView,
                sourceRect: sourceRect,
                sourceCornerRadius: sourceDelegate?.transitionInitialCornerRadius() ?? 0
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
        sourceRect: CGRect,
        sourceCornerRadius: CGFloat
    ) {
        let finalFrame = transitionContext.finalFrame(for: toVC)
        
        let imageRatio: CGFloat = 5 / 4    // 1.25 (Portrait)
        let targetMaskRatio: CGFloat = 7 / 9 // 0.77 (Landscape)
        
        let imageHeight = finalFrame.width * imageRatio // 4:5 전체 이미지 높이
        let maskHeight = finalFrame.width * targetMaskRatio // 9:7 마스크 높이
        
        let scaleX = sourceRect.width / finalFrame.width
        let scaleY = sourceRect.height / maskHeight
        
        let maskTopOffset = (imageHeight - maskHeight) / 2
        
        toView.frame = finalFrame
        toView.clipsToBounds = false
        containerView.addSubview(toView)
        toView.layoutIfNeeded()
        
        let maskView = UIView(frame: CGRect(x: 0, y: maskTopOffset, width: finalFrame.width, height: maskHeight))
        maskView.backgroundColor = UIColor.blue
        maskView.layer.borderWidth = 2
        maskView.layer.borderColor = UIColor.blue.cgColor
        maskView.layer.cornerRadius = sourceCornerRadius / scaleX
        maskView.layer.cornerCurve = .continuous
        
        toView.addSubview(maskView)
        toView.mask = maskView
        
        toView.transform = CGAffineTransform(scaleX: scaleX, y: scaleY)
        
        let maskCenterYInToView = maskTopOffset + (maskHeight / 2)
        let scaledMaskCenterY = maskCenterYInToView * scaleY
        
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

            maskView.layer.cornerRadius = 0
            maskView.frame = CGRect(origin: .zero, size: finalFrame.size)
            
            toView.layer.cornerRadius = 0
            toView.layoutIfNeeded()
        } completion: { _ in
            maskView.removeFromSuperview()
            transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
        }
    }
}
