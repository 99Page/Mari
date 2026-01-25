//
//  UIViewController + extensions.swift
//  Core
//
//  Created by 노우영 on 9/16/25.
//  Copyright © 2025 Page. All rights reserved.
//

import Foundation
import UIKit

public extension UIViewController {
    func presentWithHeight() {
        guard let sheet = self.sheetPresentationController else { return }
        
        self.modalPresentationStyle = .pageSheet
        
        let id = UISheetPresentationController.Detent.Identifier("fitContent")
        sheet.detents = [
            .custom(identifier: id) { _ in
                max(120, self.preferredContentSize.height) // 최소 높이 가드
            }
        ]
        sheet.selectedDetentIdentifier = id
        sheet.largestUndimmedDetentIdentifier = id
        sheet.prefersScrollingExpandsWhenScrolledToEdge = false
        sheet.prefersGrabberVisible = true
        sheet.preferredCornerRadius = 16
    }
}
