//
//  RimTableView.swift
//  Core
//
//  Created by 노우영 on 9/10/25.
//  Copyright © 2025 Page. All rights reserved.
//

import Foundation
import UIKit
import ComposableArchitecture

/// TableView("tableView", cell: ) {
///
/// } configure: {
///     $0.spacing = ...
///     $0.style = ...
/// }
/// .scrollEnded {
///     $0.
/// }
/// .scroll {
///
/// }
///

public protocol SectionProvidable: Identifiable & Equatable {
    associatedtype Section: Hashable, Sendable
    var section: Section { get }
}

public protocol CellConfigurable: UITableViewCell {
    associatedtype Value: SectionProvidable
    func configure(with value: UIBinding<Value?>)
}

public class RimTableView<Cell: CellConfigurable>: UITableView,  UITableViewDelegate {
    
    typealias Section = Cell.Value.Section
    typealias ID = Cell.Value.ID
    
    private var diffableDataSource: UITableViewDiffableDataSource<Section, ID>?
    var oldItems = IdentifiedArrayOf<Cell.Value>()
    public var items: UIBinding<IdentifiedArrayOf<Cell.Value>> = .constant([])
    private var observeToken: ObserveToken?
    
    private var didRowSelected: ((IndexPath) -> Void)?
    
    func updateView() {
        observeToken?.cancel()
        
        observe { [weak self] in
            guard let self else { return }
            let newItems = items.wrappedValue
            let diffs = PaulHeckel.computeDiff(from: oldItems.elements, to: newItems.elements)
            
            for diff in diffs {
                switch diff {
                case .insert(let to):
                    let item = newItems[to]
                    let id = newItems[to].id
                    append(ids: [id], to: item.section)
                case .delete(let from):
                    let item = oldItems[from]
                    let id = item.id
                    remove(id: id)
                case .move(let from, let to):
                    let from = oldItems[from].id
                    let to = newItems[to].id
                    move(from: from, to: to)
                case .update(_, let to):
                    update(item: newItems[to].id)
                }
            }
            
            oldItems = newItems
        }
    }
    
    func setupDataSource() {
        diffableDataSource = UITableViewDiffableDataSource(tableView: self, cellProvider: { tableView, indexPath, itemIdentifier in
            let cell = tableView.dequeueReusableCell(withIdentifier: "Cell") as? Cell
            
            let binding = self.items[id: itemIdentifier]
            cell?.configure(with: binding)
            
            return cell
        })
    }
    
    func move(from: ID, to: ID) {
        guard let ds = diffableDataSource else { return }
        var snapshot = ds.snapshot()
        snapshot.moveItem(from, afterItem: to)
        ds.apply(snapshot)
    }
    
    
    func update(item: ID) {
        guard let ds = diffableDataSource else { return }
        var snapshot = ds.snapshot()
        snapshot.reconfigureItems([item])
        ds.apply(snapshot)
    }
    
    func remove(id: ID) {
        guard let ds = diffableDataSource else { return }
        var snapshot = ds.snapshot()
        snapshot.deleteItems([id])
        ds.apply(snapshot)
    }
    
    func append(ids: [ID], to section: Section, animating: Bool = true) {
        guard let ds = diffableDataSource else { return }
        var snapshot = ds.snapshot()
        
        let sections = snapshot.sectionIdentifiers
        
        for id in ids {
            if !sections.contains(section) {
                snapshot.appendSections([section])
            }
            snapshot.appendItems([id], toSection: section)
        }
        
        ds.apply(snapshot, animatingDifferences: animating)
    }
    
    public func didRowSelected(closure: @escaping (IndexPath) -> Void) -> Self {
        return self
    }
    
    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        didRowSelected?(indexPath)
    }
}
