//
//  RimTextView.swift
//  Core
//
//  Created by 노우영 on 6/12/25.
//  Copyright © 2025 Page. All rights reserved.
//

import Foundation
import UIKit
import SwiftNavigation
import SnapKit
import RimMacro

public class RimTextView: UIView {
    @UIBinding var state: State
    
    let textView = UITextView(frame: .zero)
    let placeholderLabel = UILabel(frame: .zero)
    
    public init(state: UIBinding<State>) {
        self._state = state
        super.init(frame: .zero)
        
        textView.delegate = self
        makeConstraint()
        updateView()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func makeConstraint() {
        addSubview(placeholderLabel)
        addSubview(textView)
        
        textView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        placeholderLabel.snp.makeConstraints { make in
            make.top.equalToSuperview()
            make.leading.trailing.equalToSuperview()
        }
    }
    
    private func updateView() {
        observe { [weak self] in
            guard let self else { return }
            updatePlaceholder()
            updateTextView()
        }
    }
    
    private func updatePlaceholder() {
        placeholderLabel.text = state.placeholder
        placeholderLabel.isHidden = state.isPlaceholderHidden
        placeholderLabel.textColor = .gray
        placeholderLabel.font = UIFont.systemFont(ofSize: Typography.contentDescription.size, weight: Typography.contentDescription.weight)
        placeholderLabel.numberOfLines = 0
        placeholderLabel.contentMode = .top
    }
    
    private func updateTextView() {
        textView.textContainerInset = .zero
        textView.textContainer.lineFragmentPadding = 0
        textView.backgroundColor = .clear
        textView.text = state.text
        textView.font = UIFont.systemFont(ofSize: Typography.contentDescription.size, weight: Typography.contentDescription.weight)
        textView.isScrollEnabled = false
    }
    
    public struct State: Equatable {
        public var text: String
        var placeholder: String
        
        var isPlaceholderHidden: Bool {
            !text.isEmpty
        }
        
        var isFocused: Bool = false
        
        public init(text: String, placeholder: String) {
            self.text = text
            self.placeholder = placeholder
        }
    }
}

// MARK: UITextViewDelegate
extension RimTextView: UITextViewDelegate {
    public func textViewDidChange(_ textView: UITextView) {
        state.text = textView.text
    }
    
    public func textViewDidBeginEditing(_ textView: UITextView) {
        state.isFocused = true
    }
    
    public func textViewDidEndEditing(_ textView: UITextView) {
        state.isFocused = false
    }
}
