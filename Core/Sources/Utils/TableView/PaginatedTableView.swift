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
public class PaginatedTableView: UITableView {

    public var onScrollToBottom: (() -> Void)?
    private var lastFetchTime: Date?
    
    // 외부에서 설정한 delegate를 저장하기 위한 약한 참조입니다.
    // 내부적으로는 PaginatedTableView가 자신의 delegate로 설정되어 있어 scroll 감지를 수행하지만,
    // 실제 UITableViewDelegate의 동작은 이 externalDelegate를 통해 외부로 전달됩니다.
    private weak var externalDelegate: UITableViewDelegate?

    // 외부에서 delegate를 설정할 때, self가 아니라면 externalDelegate에 저장하고,
    // 내부적으로는 self를 delegate로 유지합니다.
    // 이를 통해 scrollViewDidScroll 이벤트는 내부에서 감지하면서도,
    // 외부의 delegate 메서드들은 그대로 전달할 수 있습니다.
    override public var delegate: UITableViewDelegate? {
        didSet {
            if delegate !== self {
                externalDelegate = delegate
                super.delegate = self
            }
        }
    }

    override init(frame: CGRect, style: UITableView.Style) {
        super.init(frame: frame, style: style)
        super.delegate = self
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        super.delegate = self
    }
}

extension PaginatedTableView: UITableViewDelegate {
    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        externalDelegate?.scrollViewDidScroll?(scrollView)
        
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
    

    // 객체가 메소드를 실제로 구현했는지를 확인합니다.
    // 프로토콜을 채택하더라도 실제로 구현을 하지 않았을 수 있습니다.
    // 이런 경우 false입니다.
    // 현재 객체에서 구현을 했는지를 판단 후
    // `externalDelegate`에서 구현을 했는지 확인합니다.
    // 확인이 된다면 동작을 forwardingTarget을 이용해 넘길 수 잇습니다.
    override public func responds(to aSelector: Selector!) -> Bool {
        if super.responds(to: aSelector) { return true }
        return externalDelegate?.responds(to: aSelector) ?? false
    }

    // CoR 패턴처럼, 수행할 기능을 다음 객체로 넘기는 기능을 합니다.
    override public func forwardingTarget(for aSelector: Selector!) -> Any? {
        return externalDelegate
    }
}
