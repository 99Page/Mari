//
//  Typography.swift
//  Core
//
//  Created by 노우영 on 6/12/25.
//  Copyright © 2025 Page. All rights reserved.
//

import Foundation
import UIKit

public enum Typography {
    case contentTitle
    case contentDescription
    
    var size: CGFloat {
        switch self {
        case .contentTitle: 20
        case .contentDescription: 16
        }
    }
    
    var weight: UIFont.Weight {
        switch self {
        case .contentTitle: .semibold
        case .contentDescription: .regular
        }
    }
}

extension UIFont {
    convenience init(typography: Typography) {
        self.init(descriptor: UIFont.systemFont(ofSize: typography.size, weight: typography.weight).fontDescriptor, size: typography.size)
    }
}
