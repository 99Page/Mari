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

public protocol SectionProvidable: Identifiable & Equatable {
    associatedtype Section: Hashable, Sendable
    var section: Section { get }
}

public protocol EventEmittingCell {
    associatedtype Event
    var emit: ((Event) -> Void)? { get set }
}

public protocol CellConfigurable: UITableViewCell {
    associatedtype Value: SectionProvidable
    func configure(with value: UIBinding<Value?>)
}

public class RimTableView<Cell: CellConfigurable & EventEmittingCell>: UITableView, UITableViewDelegate {
    
    typealias Section = Cell.Value.Section
    typealias ID = Cell.Value.ID
    
    private var diffableDataSource: UITableViewDiffableDataSource<Section, ID>?
    var oldItems = IdentifiedArrayOf<Cell.Value>()
    
    public var items: UIBinding<IdentifiedArrayOf<Cell.Value>> = .constant([])
    private var observeToken: ObserveToken?
    
    private var lastFetchTime: Date?
    
    private var onRowSelected: ((IndexPath) -> Void)?
    private var onTrailingSwipe: ((IndexPath) -> UISwipeActionsConfiguration?)?
    private var onPaginated: (() -> Void)?
    
    public var event: ((Cell.Event) -> Void)?
    
    public init() {
        super.init(frame: .zero, style: .plain)
        delegate = self
        setupDataSource()
        register(Cell.self, forCellReuseIdentifier: "Cell")
    }
    
    public convenience init(_ name: String, configure: ((RimTableView) -> Void)? = nil) {
        self.init()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public func updateView() {
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
            var cell = tableView.dequeueReusableCell(withIdentifier: "Cell") as? Cell
            
            let binding = self.items[id: itemIdentifier]
            cell?.configure(with: binding)
            cell?.emit = self.event
            
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
        debugPrint("append")
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
    
    @discardableResult
    public func onRowSelected(handler: @escaping (IndexPath) -> Void) -> Self {
        self.onRowSelected = handler
        return self
    }
    
    @discardableResult
    public func onPaginated(handler: @escaping () -> Void) -> Self {
        self.onPaginated = handler
        return self
    }
    
    @discardableResult
    public func onTrailingSwipe(provider: @escaping (IndexPath) -> UISwipeActionsConfiguration?) -> Self {
        self.onTrailingSwipe = provider
        return self
    }
    
    public func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        onTrailingSwipe?(indexPath)
    }
    
    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        onRowSelected?(indexPath)
    }
    
    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        paginig(scrollView: scrollView)
    }
    
    private func paginig(scrollView: UIScrollView) {
        let offsetY = scrollView.contentOffset.y
        let contentHeight = scrollView.contentSize.height
        let frameHeight = scrollView.frame.size.height

        guard offsetY > contentHeight - frameHeight * 1.5 else { return }

        let now = Date()
        
        if let last = lastFetchTime, now.timeIntervalSince(last) < 1.0 {
            return
        }

        lastFetchTime = now
        onPaginated?()
    }
}

extension RimTableView: ConstraintDescribable { }
