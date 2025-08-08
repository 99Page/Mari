//
//  PostMenuViewController.swift
//  Rim
//
//  Created by 노우영 on 8/8/25.
//

import Foundation
import ComposableArchitecture
import SnapKit
import UIKit
import SwiftUI
import Core

@Reducer
struct PostMenuFeature {
    @ObservableState
    struct State {
        
        let activeMenus: [Menu]
        
        enum Menu {
            case delete
            case report
            case block
            
            var text: String {
                switch self {
                case .delete: "삭제"
                case .report: "신고"
                case .block: "사용자 차단"
                }
            }
            
            // 아이콘: SF Symbols 이름 반환
            var iconName: String {
                switch self {
                case .delete: "trash"
                case .report: "exclamationmark.bubble"
                case .block:  "person.fill.xmark"
                }
            }
            
            // 아이콘 색상 지정
            var tintColor: UIColor {
                switch self {
                case .delete: .red
                case .report: .red
                case .block: .black
                }
            }
        }
    }
    
    enum Action {
        case delegate(Delegate)
        
        enum Delegate {
            case deleteButtonTapped
            case reportButtonTapped
            case blockUserButtonTapped
        }
    }
    
    var body: some ReducerOf<Self> {
        Reduce<State, Action> { state, action in
            switch action {
            case .delegate:
                return .none
            }
        }
    }
}

class PostMenuViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    let store: StoreOf<PostMenuFeature>
    private let tableView = UITableView()
    
    private var activeMenus: [PostMenuFeature.State.Menu] {
        store.state.activeMenus
    }
    
    init(store: StoreOf<PostMenuFeature>) {
        self.store = store
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
        makeConstraint()
    }
    
    private func makeConstraint() {
        view.addSubview(tableView)
        
        tableView.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(16)
        }
    }
    
    private func setupView() {
        view.backgroundColor = .white
        setupTableView()
    }
    
    private func setupTableView() {
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")
        tableView.tableFooterView = UIView()
        tableView.isScrollEnabled = false
        tableView.separatorStyle = .none
        tableView.backgroundColor = .clear
        // 셀 높이 지정 (아이콘 + 텍스트 가시성)
        tableView.rowHeight = 56
        
        tableView.layer.cornerRadius = 16
        tableView.clipsToBounds = false
    }
    
    // MARK: - UITableViewDataSource
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return activeMenus.count
    }
    
    // 셀 구성: 텍스트 + 아이콘
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        let menu = activeMenus[indexPath.row]
        
        var config = cell.defaultContentConfiguration()
        config.text = menu.text
        config.textProperties.color = menu.tintColor
        config.image = UIImage(systemName: menu.iconName)
        config.imageProperties.tintColor = menu.tintColor
        config.imageProperties.preferredSymbolConfiguration = .init(pointSize: 18, weight: .medium)
        
        cell.contentConfiguration = config
        cell.backgroundColor = UIColor(resource: .listBackground)
        
        return cell
    }
    
    // MARK: - UITableViewDelegate
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let menu = activeMenus[indexPath.row]
        switch menu {
        case .delete:
            store.send(.delegate(.deleteButtonTapped))
        case .report:
            store.send(.delegate(.reportButtonTapped))
        case .block:
            store.send(.delegate(.blockUserButtonTapped))
        }
        
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        cell.backgroundColor = UIColor(resource: .listBackground)

        let bounds = cell.bounds.insetBy(dx: 0, dy: 0)
        
        let corners: UIRectCorner
        if indexPath.row == 0 && indexPath.row == activeMenus.count - 1 {
            // 셀이 하나뿐일 때 → 전체 라운드
            corners = [.allCorners]
        } else if indexPath.row == 0 {
            // 섹션 첫 셀 → 상단만 라운드
            corners = [.topLeft, .topRight]
        } else if indexPath.row == activeMenus.count - 1 {
            // 섹션 마지막 셀 → 하단만 라운드
            corners = [.bottomLeft, .bottomRight]
        } else {
            // 중간 셀 → 라운드 없음
            corners = []
        }

        let path = UIBezierPath(
            roundedRect: bounds,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: 12, height: 12)
        )

        // 비선택 상태용 마스크 (셀 자체)
        let cellMask = CAShapeLayer()
        cellMask.path = path.cgPath
        cell.layer.mask = cellMask

        // 선택 상태용 마스크 (selectedBackgroundView)
        let selectedBg = UIView(frame: bounds)
        selectedBg.backgroundColor = UIColor.black.withAlphaComponent(0.05)
        let selectedMask = CAShapeLayer()
        selectedMask.path = path.cgPath
        selectedBg.layer.mask = selectedMask
        cell.selectedBackgroundView = selectedBg

        // 커스텀 구분선(divider) 추가: 마지막 셀 제외
        let dividerTag = 777_001
        // 재사용 시 중복 추가 방지
        cell.contentView.viewWithTag(dividerTag)?.removeFromSuperview()

        if indexPath.row < activeMenus.count - 1 {
            let divider = UIView()
            divider.tag = dividerTag
            divider.backgroundColor = .separator
            cell.contentView.addSubview(divider)
            divider.snp.makeConstraints { make in
                make.height.equalTo(1.0 / UIScreen.main.scale)
                make.leading.trailing.equalToSuperview().inset(16)
                make.bottom.equalToSuperview()
            }
        }
    }
}


#Preview("Others") {
    let store = Store(initialState: PostMenuFeature.State(activeMenus: [.block, .report])) {
        PostMenuFeature()
    }
    
    ViewControllerPreview {
        PostMenuViewController(store: store)
    }
}

#Preview("Mine") {
    let store = Store(initialState: PostMenuFeature.State(activeMenus: [.delete])) {
        PostMenuFeature()
    }
    
    ViewControllerPreview {
        PostMenuViewController(store: store)
    }
}
