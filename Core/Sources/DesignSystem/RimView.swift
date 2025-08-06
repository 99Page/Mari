//
//  RimView.swift
//  Core
//
//  Created by 노우영 on 7/4/25.
//  Copyright © 2025 Page. All rights reserved.
//

import Foundation
import SnapKit
import SwiftUI
import SwiftNavigation
import UIKit

public class RimView: UIView {
    
    @UIBinding var state: State
    
    public lazy var containerView: UIView = self
    
    public var layoutTarget: UIView {
        containerView === self ? self : containerView
    }
    
    public var snpTarget: ConstraintViewDSL {
        layoutTarget.snp
    }
    
    public init(state: UIBinding<State>) {
        self._state = state
        super.init(frame: .zero)
        updateView()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func updateView() {
        observe { [weak self] in
            guard let self else { return }
            self.layer.borderWidth = state.borderWidth
            self.layer.borderColor = state.borderColor.cgColor
            self.layer.cornerRadius = state.cornerRadius
            self.backgroundColor = state.backgroundColor
            self.layer.shadowColor = state.shadowColor.cgColor
            self.layer.shadowOpacity = state.shadowOpacity
            self.layer.shadowOffset = state.shadowOffset
            self.layer.shadowRadius = state.shadowRadius
            self.layer.masksToBounds = false
        }
    }
    
    public func background(_ view: UIView, insets: UIEdgeInsets) {
        view.addSubview(self)
        
        containerView = view
        
        self.snp.makeConstraints { make in
            make.top.equalToSuperview().inset(insets.top)
            make.bottom.equalToSuperview().inset(insets.bottom)
            make.leading.equalToSuperview().inset(insets.left)
            make.trailing.equalToSuperview().inset(insets.right)
        }
    }
    
    public func overlay(_ view: UIView, insets: UIEdgeInsets) {
        addSubview(view)
        
        view.snp.makeConstraints { make in
            make.top.equalToSuperview().inset(insets.top)
            make.bottom.equalToSuperview().inset(insets.bottom)
            make.leading.equalToSuperview().inset(insets.left)
            make.trailing.equalToSuperview().inset(insets.right)
        }
    }
    
    public struct State: Equatable {
        public var borderColor: UIColor
        var borderWidth: CGFloat
        var cornerRadius: CGFloat
        var backgroundColor: UIColor
        public var shadowColor: UIColor
        var shadowOpacity: Float
        var shadowOffset: CGSize
        var shadowRadius: CGFloat
        
        public init(
            borderColor: UIColor = .clear ,
            borderWidth: CGFloat = .zero,
            cornerRadius: CGFloat = .zero,
            backgroundColor: UIColor = .clear,
            shadowColor: UIColor = .clear,
            shadowOpacity: Float = 0,
            shadowOffset: CGSize = .zero,
            shadowRadius: CGFloat = 0
        ) {
            self.borderColor = borderColor
            self.borderWidth = borderWidth
            self.cornerRadius = cornerRadius
            self.backgroundColor = backgroundColor
            self.shadowColor = shadowColor
            self.shadowOpacity = shadowOpacity
            self.shadowOffset = shadowOffset
            self.shadowRadius = shadowRadius
        }
    }
}
