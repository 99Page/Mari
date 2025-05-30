//
//  UIButon + design.swift
//  Core
//
//  Created by 노우영 on 5/29/25.
//  Copyright © 2025 Page. All rights reserved.
//

import UIKit
import SwiftUI

public func horizontal(_ content: (inout ([UIView]) -> Void)) -> UIStackView {
    var views: [UIView] = []
    
    let stack = UIStackView()
    stack.axis = .horizontal
    return stack
}

@dynamicMemberLookup
public struct LabelBuilder {
    private let label: UILabel

    init(label: UILabel) {
        self.label = label
    }

    subscript<T>(dynamicMember keyPath: ReferenceWritableKeyPath<UILabel, T>) -> T {
        get { label[keyPath: keyPath] }
        set { label[keyPath: keyPath] = newValue }
    }
}

public func label(_ configure: (inout LabelBuilder) -> Void) -> UILabel {
    let label = UILabel()
    var builder = LabelBuilder(label: label)
    configure(&builder)
    return label
}
