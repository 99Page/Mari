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

@BuildView("self")
class BlockedPostView: UIView {
    
    init() {
        super.init(frame: .zero)
        addSubviews()
        activateConstraints()
        bind()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    var bluePrint: UIView {
        VerticalLayout("layout") {
            RimImageView("lockImage") {
                $0.image = .constant(.symbol(name: "lock.circle", fgColor: .gray))
            }
            .constraint(width: 100, height: 100)

            RimLabel("message") {
                $0.text = .constant("차단한 사용자의 게시물은\n볼 수 없어요.")
                $0.textColor = .constant(.black)
                $0.typography = .constant(.contentTitle)
                $0.numberOfLines = .constant(2)
            }
        } configure: {
            $0.spacing = .constant(16)
            $0.alignment = .constant(.center)
        }
        .constraint(centerX: \.centerX, centerY: \.centerY)
    }
}

@available(iOS 16.0, *)
#Preview {
    BlockedPostView()
}
