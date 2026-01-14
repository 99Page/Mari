//
//  RimScrollView.swift
//  Core
//
//  Created by 노우영 on 9/12/25.
//  Copyright © 2025 Page. All rights reserved.
//

import Foundation
import UIKit
import ComposableArchitecture

public class RimScrollView: UIScrollView, UIScrollViewDelegate, ScrollEventDescribable, ConstraintDescribable {
    public var onScrollEnd: (() -> Void)?
    public var onScroll: ((CGPoint, CGSize) -> Void)?
    
    public init() {
        super.init(frame: .zero)
        delegate = self
    }
    
    public convenience init(
        _ name: String,
        @ViewArrayBuilder _ subviews: () -> [UIView],
        configure: ((RimScrollView) -> Void)? = nil
    ) {
        self.init()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        onScroll?(scrollView.contentOffset, scrollView.contentSize)
    }
    
    public func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        onScrollEnd?()
    }
    
    public func updateView() {
        
    }
}
