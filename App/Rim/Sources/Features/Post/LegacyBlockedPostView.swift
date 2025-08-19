//
//  BlockedPostView.swift
//  Rim
//
//  Created by 노우영 on 8/11/25.
//

import Foundation
import UIKit
import ComposableArchitecture
import SnapKit
import Core
import SwiftUI

/// 변경 대상
///  
/// # After
///  
/// ```swift
///  
/// @View
/// class BlockedPostView: UIView {
///   var blueprint: some UIView {
///     VerticalLayout("stack") {
///       RimImageView("lockImage") {
///         $0.image = .symbol(name: "lock.circle")
///         $0.fgColor = .gray
///       }
///       .constraint { $0.size.equalTo(100) }
///  
///       RimLabel("message") {
///         $0.text = "차단한 사용자의 게시물은\n볼 수 없어요."
///         $0.textColor = .label
///         $0.typography = .contentTitle
///         $0.numberOfLines = 2
///       }
///     }
///     .spacing(16)
///     .alignment(.center)
///     .constraint { $0.center.equalToSuperview() }
///   }
/// }
/// ```
///
/// # Expand
///
/// ```swift
/// class BlockedPostView: UIView {
///     let stack = VStack()
///
///     init() {
///         super.init(frame: .zero)
///         updateView()
///         makeConstraint()
///     }
///
///     func makeConstraint() {
///         var parent = self
///         parent.addSubview(stack)
///
///         stack.snp.make
///     }
/// }
/// ```
///
/// # Before
///  
/// ```swift
///class BlockedPostView: UIView {
///    private let blockedIconView: RimImageView
///    private let blockedMessageLabel: RimLabel
///    private let stackView = UIStackView()
///
///    init() {
///        let lockImage = RimImageView.State(image: .symbol(name: "lock.circle", fgColor: .gray))
///        self.blockedIconView = RimImageView(state: .constant(lockImage))
///
///        let blockText = RimLabel.State(
///            text: "차단한 사용자의 게시물은\n볼 수 없어요.",
///            textColor: .label,
///            typography: .contentTitle,
///            numberOfLines: 2
///        )
///
///        self.blockedMessageLabel = RimLabel(state: .constant(blockText))
///        super.init(frame: .zero)
///        setupView()
///        makeConstraint()
///    }
///
///    required init?(coder: NSCoder) {
///        fatalError("init(coder:) has not been implemented")
///    }
///
///    private func setupView() {
///        stackView.axis = .vertical
///        stackView.alignment = .center
///        stackView.spacing = 16
///
///        addSubview(stackView)
///
///        stackView.addArrangedSubview(blockedIconView)
///        stackView.addArrangedSubview(blockedMessageLabel)
///    }
///
///
///    private func makeConstraint() {
///        stackView.snp.makeConstraints { make in
///            make.center.equalToSuperview()
///        }
///
///        blockedIconView.snp.makeConstraints { make in
///            make.width.height.equalTo(100)
///        }
///    }
///}
/// ```

class BlockedPostView: CoreView {
    
    var blueprint: UIView {
        VerticalLayout("layout") {
            UITextField()
            UITextField()
        }
        .spacing(16)
        .alignment(.center)
        .constraint(fromX: \.centerX, toX: \.centerX, fromY: \.centerY, toY: \.centerY)
    }
}

class LegacyBlockedPostView: UIView {
    private let blockedIconView: RimImageView
    private let blockedMessageLabel: RimLabel
    private let stackView = UIStackView()
    
    init() {
        let lockImage = RimImageView.State(image: .symbol(name: "lock.circle", fgColor: .gray))
        self.blockedIconView = RimImageView(state: .constant(lockImage))
        
        let blockText = RimLabel.State(
            text: "차단한 사용자의 게시물은\n볼 수 없어요.",
            textColor: .label,
            typography: .contentTitle,
            numberOfLines: 2
        )
        
        self.blockedMessageLabel = RimLabel(state: .constant(blockText))
        super.init(frame: .zero)
        setupView()
        makeConstraint()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupView() {
        stackView.axis = .vertical
        stackView.alignment = .center
        stackView.spacing = 16

        addSubview(stackView)

        stackView.addArrangedSubview(blockedIconView)
        stackView.addArrangedSubview(blockedMessageLabel)
    }
    
    
    private func makeConstraint() {
        stackView.snp.makeConstraints { make in
            make.centerX.equalTo(self.snp.centerX)
        }
        stackView.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }

        blockedIconView.snp.makeConstraints { make in
            make.width.height.equalTo(100)
        }
    }
}

@available(iOS 16.0, *)
#Preview {
    ViewPreview(fromY: \.centerY, toY: \.centerY) {
        LegacyBlockedPostView()
    }
}
