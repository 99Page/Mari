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
    case logoTitle
    case logoDescription
    
    case contentTitle
    case contentDescription
    
    case primaryAction
    
    case hint
    
    var size: CGFloat {
        switch self {
        case .logoTitle: 30
        case .logoDescription: 24
            
        case .contentTitle: 20
        case .contentDescription: 16
            
        case .primaryAction: 20
            
        case .hint: 14
        }
    }
    
    var weight: UIFont.Weight {
        switch self {
        case .logoTitle: .bold
        case .logoDescription: .bold
            
        case .contentTitle: .semibold
        case .contentDescription: .regular
            
        case .primaryAction: .regular
            
        case .hint: .regular
        }
    }
}

extension UIFont {
    convenience init(typography: Typography) {
        self.init(descriptor: UIFont.systemFont(ofSize: typography.size, weight: typography.weight).fontDescriptor, size: typography.size)
    }
}
