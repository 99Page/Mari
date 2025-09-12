//
//  ScrollEventDescribable.swift
//  Core
//
//  Created by 노우영 on 9/12/25.
//  Copyright © 2025 Page. All rights reserved.
//

import Foundation

public protocol ScrollEventDescribable: AnyObject {
    var onScroll: ((_ contentOffset: CGPoint, _ contentSize: CGSize) -> Void)? { get set }
    var onScrollEnd: (() -> Void)? { get set }
}

extension ScrollEventDescribable {
    public func onScroll(handler: @escaping ((_ contentOffset: CGPoint, _ contentSize: CGSize) -> Void)) -> Self {
        self.onScroll = handler
        return self
    }
    
    public func onScrollEnd(handler: @escaping (() -> Void)) -> Self {
        self.onScrollEnd = handler
        return self
    }
}
