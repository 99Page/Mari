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
        _ fromX: KeyPath<ConstraintMaker, ConstraintMakerExtendable>,
        equalTo toX: KeyPath<ConstraintLayoutGuideDSL, ConstraintItem>,
        _ fromY: KeyPath<ConstraintMaker, ConstraintMakerExtendable>,
        equalTo toY: KeyPath<ConstraintLayoutGuideDSL, ConstraintItem>
    ) -> Self
}

public extension ConstraintDescribable {
    func constraint(
        _ fromX: KeyPath<ConstraintMaker, ConstraintMakerExtendable>,
        equalTo toX: KeyPath<ConstraintLayoutGuideDSL, ConstraintItem>,
        _ fromY: KeyPath<ConstraintMaker, ConstraintMakerExtendable>,
        equalTo toY: KeyPath<ConstraintLayoutGuideDSL, ConstraintItem>
    ) -> Self {
        return self
    }
}
