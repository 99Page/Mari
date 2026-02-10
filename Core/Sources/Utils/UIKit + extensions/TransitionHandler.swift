//
//  TransitionHandler.swift
//  Core
//
//  Created by 노우영 on 2/11/26.
//  Copyright © 2026 Page. All rights reserved.
//

import Foundation
import UIKit

public protocol TransitionHandler: UIViewController {
    func transitionAnimator(
        operation: UINavigationController.Operation,
        from fromVC: UIViewController,
        to toVC: UIViewController
    ) -> UIViewControllerAnimatedTransitioning?
}

