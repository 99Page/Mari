//
//  CoreFont.swift
//  Core
//
//  Created by 노우영 on 1/17/26.
//  Copyright © 2026 Page. All rights reserved.
//

import Foundation
import SwiftUI

public enum CoreFont {
    case spoqa(Weight)
    
    public enum Weight: String {
        case bold = "Bold"
        case medium = "Medium"
        case regular = "Regular"
        case light = "Light"
        case thin = "Thin"
    }
    
    public var name: String {
        switch self {
        case .spoqa(let weight):
            return "SpoqaHanSansNeo-\(weight.rawValue)"
        }
    }
}
