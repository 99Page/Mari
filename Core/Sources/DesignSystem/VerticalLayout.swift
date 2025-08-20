//
//  VerticalLayout.swift
//  Core
//
//  Created by 노우영 on 8/19/25.
//  Copyright © 2025 Page. All rights reserved.
//

import UIKit
import SnapKit

public protocol CoreView {
    var bluePrint: UIView { get } 
}

@resultBuilder
public enum ViewArrayBuilder {
    public static func buildBlock(_ components: UIView...) -> [UIView] { components }
    public static func buildOptional(_ component: [UIView]?) -> [UIView] { component ?? [] }
    public static func buildEither(first component: [UIView]) -> [UIView] { component }
    public static func buildEither(second component: [UIView]) -> [UIView] { component }
    public static func buildArray(_ components: [[UIView]]) -> [UIView] { components.flatMap { $0 } }
}

public class VerticalLayout: UIStackView {
    
    public init() {
        super.init(frame: .zero)
    }
    
    public init(_ name: String, @ViewArrayBuilder _ subviews: () -> [UIView]) {
        super.init(frame: .zero)
    }
    
    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // ===== modifier 유틸(선택) =====
    /// 스택 간격 설정
    @discardableResult
    public func spacing(_ value: CGFloat) -> Self { self.spacing = value; return self }

    /// 정렬 설정
    @discardableResult
    public func alignment(_ value: UIStackView.Alignment) -> Self { self.alignment = value; return self }

    /// 분배 방식 설정
    @discardableResult
    public func distribution(_ value: UIStackView.Distribution) -> Self { self.distribution = value; return self }
    
    @discardableResult
    public func constraint(fromX: KeyPath<ConstraintMaker, ConstraintMakerExtendable>, toX: KeyPath<ConstraintLayoutGuideDSL, ConstraintItem>, fromY: KeyPath<ConstraintMaker, ConstraintMakerExtendable>, toY: KeyPath<ConstraintLayoutGuideDSL, ConstraintItem>) -> Self {
        return self
    }
}
