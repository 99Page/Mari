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

class BlockedPostView: UIView {
    private let contentView = UIView()
    private let blockedIconView: RimImageView
    private let blockedMessageLabel: RimLabel
    
    init() {
        let lockImage = RimImageView.State(image: .symbol(name: "lock.circle", fgColor: .gray))
        self.blockedIconView = RimImageView(state: .constant(lockImage))
        
        let blockText = RimLabel.State(
            text: "차단한 사용자의 게시물은\n볼 수 없어요",
            textColor: .black,
            typography: .contentTitle,
            numberOfLines: 2
        )
        
        self.blockedMessageLabel = RimLabel(state: .constant(blockText))
        super.init(frame: .zero)
        makeConstraint()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func makeConstraint() {
        addSubview(contentView)
        contentView.addSubview(blockedIconView)
        contentView.addSubview(blockedMessageLabel)
        
        contentView.snp.makeConstraints { make in
            make.centerY.centerX.equalToSuperview()
        }
        
        blockedIconView.snp.makeConstraints { make in
            make.width.height.equalTo(100)
            make.top.equalToSuperview()
            make.centerX.equalToSuperview()
        }
        
        blockedMessageLabel.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalTo(blockedIconView.snp.bottom).offset(16)
            make.bottom.equalToSuperview()
        }
    }
}

@available(iOS 16.0, *)
#Preview {
    ViewPreview(fromY: \.centerY, toY: \.centerY) {
        BlockedPostView()
    }
}
