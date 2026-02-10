//
//  UITableView + observe.swift
//  Core
//
//  Created by 노우영 on 2/10/26.
//  Copyright © 2026 Page. All rights reserved.
//

import Foundation
import ComposableArchitecture
import UIKit

public extension UITableView {
    
    /// TCA의 `IdentifiedArray` 상태를 바인딩하여 자동으로 섹션을 구성하고 셀을 렌더링하는 `UITableView`를 생성합니다.
    ///
    /// 이 이니셜라이저는 내부적으로 `UITableViewDiffableDataSource`를 사용하며,
    /// `SectionProvidable` 프로토콜을 준수하는 데이터의 `section` 속성을 기준으로 자동으로 그룹핑을 수행합니다.
    ///
    /// - Parameters:
    ///   - binding: 테이블 뷰에 표시할 데이터 배열에 대한 바인딩 (`UIBinding<IdentifiedArrayOf<Element>>`).
    ///   - cellProvider: 각 셀을 구성하는 클로저. 테이블 뷰, 인덱스 패스, 그리고 해당 아이템 모델을 인자로 받습니다.
    ///
    /// - Generic Parameters:
    ///   - Element: 테이블 뷰에 표시될 데이터 모델 타입입니다.
    ///     `Identifiable`, `Equatable`, `SectionProvidable`을 준수해야 하며, `ID`는 `Hashable`이어야 합니다.
    ///
    /// - Note:
    ///   1. 섹션의 정렬 순서는 현재 `hashValue`를 기준으로 오름차순 정렬됩니다. (특정 순서가 필요하다면 수정이 필요할 수 있습니다.)
    ///   2. 스냅샷 적용 시 애니메이션은 비활성화(`animatingDifferences: false`)되어 있습니다.
    ///
    /// - Example:
    /// ```swift
    /// // Model
    /// struct Post: Identifiable, Equatable, SectionProvidable {
    ///     let id: UUID
    ///     var section: String { category } // 카테고리별로 섹션 구분
    ///     // ...
    /// }
    ///
    /// // ViewController
    /// self.tableView = UITableView($store.posts) { tableView, indexPath, post in
    ///     let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
    ///     cell.textLabel?.text = post.title
    ///     return cell
    /// }
    /// ```
    convenience init<Element: SectionProvidable & Equatable>(
        _ binding: UIBinding<IdentifiedArrayOf<Element>>,
        cellProvider: @escaping (UITableView, IndexPath, Element) -> UITableViewCell?
    ) where Element.ID: Hashable {
        
        self.init()
        
        let dataSource = UITableViewDiffableDataSource<AnyHashableSendable, AnyHashableSendable>(tableView: self) { [binding] tableView, indexPath, idWrapper in
            guard let item = binding.wrappedValue[id: idWrapper.base as! Element.ID] else { return nil }
            return cellProvider(tableView, indexPath, item)
        }
        self.diffableDataSource = dataSource
        
        observe { [weak self] in
            guard let self = self, let ds = self.diffableDataSource else { return }
            
            let items = binding.wrappedValue
            var snapshot = NSDiffableDataSourceSnapshot<AnyHashableSendable, AnyHashableSendable>()
            
            let groupedItems = Dictionary(grouping: items) { $0.section }
            
            
            let sortedSections = groupedItems.keys.sorted { section1, section2 in
                return section1.hashValue < section2.hashValue
            }
            
            for section in sortedSections {
                let sectionWrapper = AnyHashableSendable(section)
                let sectionItems = groupedItems[section] ?? []
                
                snapshot.appendSections([sectionWrapper])
                let itemIDs = sectionItems.map { AnyHashableSendable($0.id) }
                snapshot.appendItems(itemIDs, toSection: sectionWrapper)
            }
            
            ds.apply(snapshot, animatingDifferences: false)
        }
    }
}

extension UITableView {
    /// 내부 Diffable Data Source (ID는 AnyHashable로 소거)
    /// `objc_getAssociated`를 활용해서 exntension에서 stored property를 추가할 수 있다
    private var diffableDataSource: UITableViewDiffableDataSource<AnyHashableSendable, AnyHashableSendable>? {
        get { objc_getAssociatedObject(self, &AssocKeys.dataSource) as? UITableViewDiffableDataSource<AnyHashableSendable, AnyHashableSendable> }
        set { objc_setAssociatedObject(self, &AssocKeys.dataSource, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
    }
}

typealias SectionID = AnyHashableSendable
typealias ItemID = AnyHashableSendable

private struct AssocKeys {
    //  objc_getAssociatedObject에 사용할 key 값들은 모두 동일한 값을 가져야한다
    static var oldItems: UInt8 = 0
    static var dataSource: UInt8 = 0
    static var sectionProvider: UInt8 = 0
}
