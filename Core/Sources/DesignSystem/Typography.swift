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
    case userContent
    
    var size: CGFloat {
        switch self {
        case .userContent: 18
        }
    }
    
    var weight: UIFont.Weight {
        switch self {
        case .userContent: .regular
        }
    }
}
