//
//  RimLabel.swift
//  Core
//
//  Created by 노우영 on 6/12/25.
//  Copyright © 2025 Page. All rights reserved.
//

import Foundation
import UIKit
import SnapKit
import SwiftUI
import SwiftNavigation

public class RimLabel: UIView {
    @UIBinding var state: State
    
    let label = UILabel(frame: .zero)
    
    public var respondsToKeyboard: Bool = false
    
    private var height: CGFloat = 0
    private var keyboardAvoidClosure: ((_ make: ConstraintMaker) -> Void)?
    
    public init(state: UIBinding<State>) {
        self._state = state
        super.init(frame: .zero)
        makeConstraint()
        updateView()
        setupKeyboardObserver()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public func withKeyboardAvoid(height: CGFloat, closure: @escaping (_ make: ConstraintMaker) -> Void) {
        self.snp.makeConstraints { make in
            closure(make)
        }
        
        self.height = height
        self.respondsToKeyboard = true
        self.keyboardAvoidClosure = closure
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
    
    private func setupKeyboardObserver() {
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(_:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(_:)), name: UIResponder.keyboardWillHideNotification, object: nil)
    }

    @objc private func keyboardWillShow(_ notification: Notification) {
        guard respondsToKeyboard,
              let userInfo = notification.userInfo,
              let keyboardFrame = userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else { return }

        guard let superview = self.superview else { return }
        let safeAreaBottom = superview.safeAreaInsets.bottom

        self.snp.remakeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(16)
            make.bottom.equalTo(superview.safeAreaLayoutGuide.snp.bottom).offset(-keyboardFrame.height + safeAreaBottom - 16)
            make.height.equalTo(height)
        }

        UIView.animate(withDuration: 0.3) {
            superview.layoutIfNeeded()
        }
    }

    @objc private func keyboardWillHide(_ notification: Notification) {
        guard respondsToKeyboard else { return }
        guard let closure = self.keyboardAvoidClosure else { return }
        guard let superview else { return }
        
        self.snp.remakeConstraints { make in
            closure(make)
        }
        
        UIView.animate(withDuration: 0.3) {
            superview.layoutIfNeeded()
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
            .paragraphStyle: paragraphStyle,
            .font: UIFont(typography: state.typography)
        ]
        
        label.attributedText = NSAttributedString(string: state.text, attributes: attributes)
    }
}

public extension RimLabel {
    struct State: Equatable {
        public var text: String
        var textColor: UIColor
        var alignment: NSTextAlignment
        
        var typography: Typography
        var background: UIView.Background?
        
        public init(text: String, textColor: UIColor, typography: Typography = .contentDescription, alignment: NSTextAlignment = .center, background: UIView.Background? = nil) {
            self.text = text
            self.textColor = textColor
            self.typography = typography
            self.alignment = alignment
            self.background = background
        }
        
    }
}
