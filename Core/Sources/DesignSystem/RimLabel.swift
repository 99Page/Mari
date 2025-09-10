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

public class RimLabel: RimView, ConstraintDescribable {
    
    @UIBinding var labelState: State
    
    
    public var text: UIBinding<String> = .constant("")
    public var textColor: UIBinding<UIColor> = .constant(.black)
    public var alignment: UIBinding<NSTextAlignment> = .constant(.center)
    public var typography: UIBinding<Typography> = .constant(.contentDescription)
    public var isEnabled: UIBinding<Bool> = .constant(true)
    public var numberOfLines: UIBinding<Int> = .constant(0)
    
    let label = UILabel(frame: .zero)
    public var respondsToKeyboard: Bool = false
    private var height: CGFloat = 0
    private var keyboardAvoidClosure: ((_ make: ConstraintMaker) -> Void)?
    
    private var observeToken: ObserveToken?
    
    public init() {
        self.labelState = .init()
        super.init(state: .constant(.init()))
        makeConstraint()
        updateView()
        setupKeyboardObserver()
    }
    
    public init(_ name: String, configure: ((RimLabel) -> Void)? = nil) {
        self.labelState = .init()
        super.init(state: .constant(.init()))
    }
    
    public init(state: UIBinding<State>) {
        self._labelState = state
        super.init(state: state.appearance)
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
    
    public func updateView() {
        observeToken?.cancel()
        
        observeToken = observe { [weak self] in
            guard let self else { return }
            updateAttributedString()
            isUserInteractionEnabled = isEnabled.wrappedValue
            label.numberOfLines = numberOfLines.wrappedValue
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
    
    private func updateAttributedString() {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = alignment.wrappedValue
        paragraphStyle.lineSpacing = 0
        paragraphStyle.minimumLineHeight = typography.wrappedValue.lineHeight
        paragraphStyle.maximumLineHeight = typography.wrappedValue.lineHeight
        
        let attributes: [NSAttributedString.Key: Any] = [
            .foregroundColor: textColor.wrappedValue,
            .paragraphStyle: paragraphStyle,
            .font: UIFont(typography: typography.wrappedValue),
            .baselineOffset: 0
        ]
        
        self.label.attributedText = NSAttributedString(string: text.wrappedValue, attributes: attributes)
    }
}

public extension RimLabel {
    struct State: Equatable {
        var appearance: RimView.State
        
        public init(
            appearance: RimView.State = .init()
        ) {
            self.appearance = appearance
        }
        
    }
}
