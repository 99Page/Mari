//
//  ConstraintDescribable.swift
//  Core
//
//  Created by 노우영 on 9/9/25.
//  Copyright © 2025 Page. All rights reserved.
//

import Foundation
import SnapKit

public protocol ConstraintDescribable {
    func constraint(
        width: (any ConstraintRelatableTarget)?,
        height: (any ConstraintRelatableTarget)?,
        centerX: KeyPath<ConstraintLayoutGuideDSL, ConstraintItem>?,
        centerY: KeyPath<ConstraintLayoutGuideDSL, ConstraintItem>?
    ) -> Self
    
    func constraint(
        leading: KeyPath<ConstraintLayoutGuideDSL, ConstraintItem>?,
        trailing: KeyPath<ConstraintLayoutGuideDSL, ConstraintItem>??,
        top: KeyPath<ConstraintLayoutGuideDSL, ConstraintItem>?,
        bottom: KeyPath<ConstraintLayoutGuideDSL, ConstraintItem>?
    ) -> Self
}

public extension ConstraintDescribable {
    func constraint(
        width: (any ConstraintRelatableTarget)? = nil,
        height: (any ConstraintRelatableTarget)? = nil,
        centerX: KeyPath<ConstraintLayoutGuideDSL, ConstraintItem>? = nil,
        centerY: KeyPath<ConstraintLayoutGuideDSL, ConstraintItem>? = nil
    ) -> Self {
        return self
    }
    
    func constraint(
        leading: KeyPath<ConstraintLayoutGuideDSL, ConstraintItem>? = nil,
        trailing: KeyPath<ConstraintLayoutGuideDSL, ConstraintItem>?? = nil,
        top: KeyPath<ConstraintLayoutGuideDSL, ConstraintItem>? = nil,
        bottom: KeyPath<ConstraintLayoutGuideDSL, ConstraintItem>? = nil
    ) -> Self {
        return self
    }
}
