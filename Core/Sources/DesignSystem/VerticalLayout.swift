//
//  VerticalLayout.swift
//  Core
//
//  Created by 노우영 on 8/19/25.
//  Copyright © 2025 Page. All rights reserved.
//

import UIKit
import SnapKit
import ComposableArchitecture

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

public class VerticalLayout: UIView, ConstraintDescribable {
    
    let stack = UIStackView()
    
    public var spacing: UIBinding<CGFloat> = .constant(.zero)
    public var distribution: UIBinding<UIStackView.Distribution> = .constant(.fill)
    public var alignment: UIBinding<UIStackView.Alignment> = .constant(.fill)
    
    public init() {
        super.init(frame: .zero)
        makeConstraint()
        updateView()
    }
    
    public init(
        _ name: String, @ViewArrayBuilder
        _ subviews: () -> [UIView],
        configure: ((VerticalLayout) -> Void)? = nil
    ) {
        super.init(frame: .zero)
    }
    
    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public func makeConstraint() {
        addSubview(stack)
        
        stack.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
    
    public func updateView() {
        observe { [weak self] in
            guard let self else { return }
            stack.spacing = spacing.wrappedValue
            stack.distribution = distribution.wrappedValue
            stack.alignment = alignment.wrappedValue
        }
    }
    
    public func addArrangedSubview(_ view: UIView) {
        stack.addArrangedSubview(view)
    }
}
