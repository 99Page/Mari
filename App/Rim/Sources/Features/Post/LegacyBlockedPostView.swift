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
import RimMacro

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
///     .constraint(\.centerX, equalTo: \.centerX, \.centerY, equalTo: \.centerY)
///   }
/// }
/// ```
///
/// # Expand
///
/// ```swift
/// class BlockedPostView: UIView {
///
///     var bluePrint: UIView {
///         VerticalLayout("stack") {
///             RimImageView("lockImage")
///
///             RimLabel("message")
///         }
///         .spacing(16)
///         .alignment(.center)
///         .constraint(\.centerX, equalTo: \.centerX, \.centerY, equalTo: \.centerY)
///     }
///
///     let stack = VStack()
///     let lockImage = RimImageView()
///     let message = RimLabel()
///
///     init() {
///         super.init(frame: .zero)
///         updateView()
///         makeConstraint()
///     }
///
///     func makeConstraint() {
///         self.addSubview(stack)
///
///         stack.addArrangedSubview(lockImage)
///         stack.addArrangedSubview(message)
///
///         stackView.snp.makeConstraints { make in
///             make[keyPath: \.centerX].equalTo(self.snp[keyPath: \.centerX])
///             make[keyPath: \.centerY].equalTo(self.snp[keyPath: \.centerY])
///         }
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

@BuildView
class BlockedPostView: UIView {
    var bluePrint: UIView {
        VerticalLayout("layout") {
            RimImageView("lockImage")
            
            RimLabel("message")
        }
        .spacing(16)
        .alignment(.center)
        .constraint(\.centerX, equalTo: \.centerX, \.centerY, equalTo: \.centerY)
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
            make.leading.equalTo(self.snp.trailing)
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
