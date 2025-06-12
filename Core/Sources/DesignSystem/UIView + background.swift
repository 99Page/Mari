//
//  UIView + background.swift
//  Core
//
//  Created by 노우영 on 6/12/25.
//  Copyright © 2025 Page. All rights reserved.
//

import Foundation
import UIKit

public extension UIView {
    func background(_ config: Background) {
        backgroundColor = config.color
        layer.cornerRadius = config.cornerRadius
        layer.masksToBounds = true
    }

    struct Background {
        let color: UIColor
        let cornerRadius: CGFloat

        public init(color: UIColor, cornerRadius: CGFloat) {
            self.color = color
            self.cornerRadius = cornerRadius
        }
    }
}
