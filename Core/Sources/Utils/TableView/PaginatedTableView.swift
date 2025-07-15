//
//  PaginatedTableView.swift
//  Core
//
//  Created by 노우영 on 7/15/25.
//  Copyright © 2025 Page. All rights reserved.
//

import Foundation
import UIKit

/// 페이징 기능이 내장된 커스텀 UITableView 클래스입니다.
/// 스크롤이 하단에 도달하면 지정된 시간 간격(1초)에 따라 onScrollToBottom 클로저를 호출합니다.
/// dataSource는 별도로 지정해야합니다.
public class PaginatedTableView: UITableView, UITableViewDelegate {

    public var onScrollToBottom: (() -> Void)?

    private var lastFetchTime: Date?

    override init(frame: CGRect, style: UITableView.Style) {
        super.init(frame: frame, style: style)
        delegate = self
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        delegate = self
    }

    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let offsetY = scrollView.contentOffset.y
        let contentHeight = scrollView.contentSize.height
        let frameHeight = scrollView.frame.size.height

        guard offsetY > contentHeight - frameHeight * 1.5 else { return }

        let now = Date()
        if let last = lastFetchTime, now.timeIntervalSince(last) < 1.0 {
            return
        }

        lastFetchTime = now
        onScrollToBottom?()
    }
}
