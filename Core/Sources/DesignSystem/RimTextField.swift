//
//  RimTextField.swift
//  Core
//
//  Created by 노우영 on 7/10/25.
//  Copyright © 2025 Page. All rights reserved.
//

import Foundation
import UIKit
import SnapKit
import SwiftUI
import SwiftNavigation

public class RimTextField: RimView {
    
    @UIBinding var textFieldState: State
    
    private let textField = UITextField()
    
    public init(state: UIBinding<State>) {
        self._textFieldState = state
        super.init(state: state.appearance)
        makeConstraint()
        setupTextField()
        updateView()
    }
    
    private func updateView() {
        observe { [weak self] in
            guard let self else { return }
            updateAttributedText()
            updateAttributedPlaceholder()
        }
    }
    
    private func updateAttributedPlaceholder() {
        let attributes = makeAttributes(fgColor: .systemGray)
        textField.attributedPlaceholder = NSAttributedString(
            string: textFieldState.placeholder,
            attributes: attributes
        )
    }
    
    private func updateAttributedText() {
        let attributes = makeAttributes(fgColor: textFieldState.textColor)
        
        textField.attributedText = NSAttributedString(string: textFieldState.text, attributes: attributes)
    }
    
    private func makeAttributes(fgColor: UIColor) -> [NSAttributedString.Key: Any] {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = textFieldState.alignment
        paragraphStyle.lineSpacing = 0
        paragraphStyle.minimumLineHeight = textFieldState.typography.size
        paragraphStyle.maximumLineHeight = textFieldState.typography.size
        
        let attributes: [NSAttributedString.Key: Any] = [
            .foregroundColor: fgColor,
            .paragraphStyle: paragraphStyle,
            .font: UIFont(typography: textFieldState.typography),
            .baselineOffset: 0
            
        ]
        
        return attributes
    }
    
    private func makeConstraint() {
        addSubview(textField)
        
        textField.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
    
    @MainActor required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public struct State: Equatable {
        public var text: String
        var textColor: UIColor
        var alignment: NSTextAlignment
        
        var typography: Typography
        var placeholder: String
        var appearance = RimView.State()
        
        public init(text: String, textColor: UIColor = .black, alignment: NSTextAlignment = .center, typography: Typography = .contentDescription, placeholder: String, appearance: RimView.State = RimView.State()) {
            self.text = text
            self.textColor = textColor
            self.alignment = alignment
            self.typography = typography
            self.placeholder = placeholder
            self.appearance = appearance
        }
    }
    
    private func setupTextField() {
        textField.addTarget(self, action: #selector(textFieldDidChange), for: .editingChanged)
    }

    @objc private func textFieldDidChange() {
        textFieldState.text = textField.text ?? ""
    }
}

#Preview {
    @UIBinding @Previewable
    var state = RimTextField.State(text: "", typography: .contentTitle, placeholder: "placeholder")
    
    ViewPreview(fromY: \.centerY, toY: \.centerY) {
        RimTextField(state: $state)
    }
}
