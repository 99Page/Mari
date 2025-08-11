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
    struct State: Equatable {
        @Presents var alert: AlertState<Action.Alert>?
        
        let activeMenus: [Menu]
        
        enum Menu: Equatable {
            case delete
            case report
            case block
            case unblock
            
            var text: String {
                switch self {
                case .delete: "삭제"
                case .report: "신고"
                case .block: "사용자 차단"
                case .unblock: "사용자 차단 해제"
                }
            }
            
            // 아이콘: SF Symbols 이름 반환
            var iconName: String {
                switch self {
                case .delete: "trash"
                case .report: "exclamationmark.bubble"
                case .block:  "person.fill.xmark"
                case .unblock: "person.fill.checkmark"
                }
            }
            
            // 아이콘 색상 지정
            var tintColor: UIColor {
                switch self {
                case .delete: .red
                case .report: .red
                case .block: .black
                case .unblock: .black
                }
            }
        }
    }
    
    enum Action: ViewAction {
        case alert(PresentationAction<Alert>)
        case view(View)
        case delegate(Delegate)
        
        @CasePathable
        enum View: BindableAction {
            case binding(BindingAction<State>)
            case deleteButtonTapped
            case reportButtonTapped
            case blockUserButtonTapped
            case unblockUserButtonTapped
        }
        
        @CasePathable
        enum Delegate {
            case deletePost
            case reportPost
            case blocksUser
            case unblocksUser
        }
        
        @CasePathable
        enum Alert: Equatable {
            case report
            case delete
            case block
            case cancel
            case unblock
        }
    }
    
    var body: some ReducerOf<Self> {
        BindingReducer(action: \.view)
        
        Reduce<State, Action> { state, action in
            switch action {
            case .view(.deleteButtonTapped):
                state.alert = .delete
                return .none
            case .view(.unblockUserButtonTapped):
                state.alert = .unblock
                return .none
            case .view(.reportButtonTapped):
                state.alert = .report
                return .none
            case .view(.blockUserButtonTapped):
                state.alert = .block
                return .none
            case .view(.binding):
                return .none
            case .alert(.presented(.unblock)):
                return .send(.delegate(.unblocksUser))
            case .alert(.presented(.block)):
                return .send(.delegate(.blocksUser))
            case .alert(.presented(.report)):
                return .send(.delegate(.reportPost))
            case .alert(.presented(.delete)):
                return .send(.delegate(.deletePost))
            case .alert:
                return .none
            case .delegate:
                return .none
            }
        }
        .ifLet(\.$alert, action: \.alert)
    }
}

@ViewAction(for: PostMenuFeature.self)
class PostMenuViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    @UIBindable var store: StoreOf<PostMenuFeature>
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
        
        present(item: $store.scope(state: \.alert, action: \.alert)) { store in
            UIAlertController(store: store)
        }
    }
    
    private func makeConstraint() {
        view.addSubview(tableView)
        
        tableView.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(16)
            make.top.bottom.equalToSuperview().inset(32)
        }
    }
    
    private func setupView() {
        view.backgroundColor = .white
        setupTableView()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        tableView.layoutIfNeeded()

        // 시트 최대 높이 한도 (화면의 90%)
        let maxHeight = UIScreen.main.bounds.height * 0.9
        let height = min(tableView.contentSize.height + 50, maxHeight)

        // 시트가 참조할 컨텐츠 높이
        preferredContentSize = CGSize(width: view.bounds.width, height: height)
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
            send(.deleteButtonTapped)
        case .report:
            send(.reportButtonTapped)
        case .block:
            send(.blockUserButtonTapped)
        case .unblock:
            send(.unblockUserButtonTapped)
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

private extension AlertState where Action == PostMenuFeature.Action.Alert {
    static let block = AlertState {
        TextState("사용자를 차단할까요?")
    } actions: {
        ButtonState(role: .destructive, action: .block) {
            TextState("차단")
        }
        
        ButtonState(role: .cancel, action: .cancel) {
            TextState("취소")
        }
    }
    
    static let unblock = AlertState {
        TextState("사용자 차단을 해제할까요?")
    } actions: {
        ButtonState(role: .destructive, action: .unblock) {
            TextState("해제")
        }
        
        ButtonState(role: .cancel, action: .cancel) {
            TextState("취소")
        }
    }
    
    static let report = AlertState {
        TextState("이 게시글을 신고할까요?")
    } actions: {
        ButtonState(role: .destructive, action: .report) {
            TextState("신고")
        }
        
        ButtonState(role: .cancel, action: .cancel) {
            TextState("취소")
        }
    }
    
    static let delete = AlertState {
        TextState("이 게시글을 삭제할까요?")
    } actions: {
        ButtonState(role: .destructive, action: .delete) {
            TextState("삭제")
        }
        
        ButtonState(role: .cancel, action: .cancel) {
            TextState("취소")
        }
    }
}


#Preview("unblocked user") {
    let store = Store(initialState: PostMenuFeature.State(activeMenus: [.block, .report])) {
        PostMenuFeature()
    }
    
    ViewControllerPreview {
        PostMenuViewController(store: store)
    }
}

#Preview("blocked user") {
    let store = Store(initialState: PostMenuFeature.State(activeMenus: [.unblock])) {
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
