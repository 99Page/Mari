//
//  RimLabel.swift
//  Core
//
//  Created by 노우영 on 6/12/25.
//  Copyright © 2025 Page. All rights reserved.
//

import Foundation
import UIKit
import ComposableArchitecture
import SnapKit
import SwiftUI

public class RimLabel: UIView {
    @UIBinding var state: State
    
    let label = UILabel(frame: .zero)
    
    public init(state: UIBinding<State>) {
        self._state = state
        super.init(frame: .zero)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public func configure() {
        makeConstraint()
        updateView()
    }
    
    private func makeConstraint() {
        addSubview(label)
        
        label.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
    
    private func updateView() {
        observe { [weak self] in
            guard let self else { return }
            updateAttributedString()
            updateBackground()
        }
    }
    
    private func updateBackground() {
        guard let background = state.background else { return }
        self.background(background)
    }
    
    private func updateAttributedString() {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = state.alignment
        
        let attributes: [NSAttributedString.Key: Any] = [
            .foregroundColor: state.textColor,
            .paragraphStyle: paragraphStyle
        ]
        
        label.attributedText = NSAttributedString(string: state.text, attributes: attributes)
    }
}

public extension RimLabel {
    struct State: Equatable {
        var text: String
        var textColor: UIColor
        var alignment: NSTextAlignment
        
        var background: UIView.Background?
        
        public init(text: String, textColor: UIColor, alignment: NSTextAlignment = .center, background: UIView.Background? = nil) {
            self.text = text
            self.textColor = textColor
            self.alignment = alignment
            self.background = background
        }
    }
}
