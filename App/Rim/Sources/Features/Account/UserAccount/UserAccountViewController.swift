//
//  UserAccountViewController.swift
//  Rim
//
//  Created by 노우영 on 6/26/25.
//

import Foundation
import UIKit
import ComposableArchitecture
import SnapKit
import SwiftUI
import Core

@Reducer
struct UserAccountFeature {
    @ObservableState
    struct State: Equatable {
        @Presents var alert: AlertState<Action.Alert>?
        @Shared(.uid) var uid
        var isProgressViewPresented = false
    }
    
    enum Action: ViewAction {
        case view(View)
        case delegate(Delegate)
        case alert(PresentationAction<Alert>)
        case showWithdrawalFailAlert
        case dismissProgressView
        
        @CasePathable
        enum View: BindableAction {
            case logoutButtonTapped
            case binding(BindingAction<State>)
            case withdrawalButtonTapped
        }
        
        @CasePathable
        enum Delegate {
            case logout
        }
        
        @CasePathable
        enum Alert: Equatable {
            case confirmWithdrawal
            case dismissAlert
        }
    }
    
    @Dependency(\.accountClient) var accountClient
    
    var body: some ReducerOf<Self> {
        Reduce<State, Action> { state, action in
            switch action {
            case .view(.logoutButtonTapped):
                state.$uid.withLock { $0 = nil }
                return .run { send in
                    await send(.delegate(.logout))
                }
                
            case .view(.withdrawalButtonTapped):
                state.alert = AlertState {
                    TextState("계정을 삭제하시나요?")
                } actions: {
                    ButtonState(role: .cancel, action: .dismissAlert) {
                        TextState("취소")
                    }
                    
                    ButtonState(role: .destructive, action: .confirmWithdrawal) {
                        TextState("삭제")
                    }
                } message: {
                    TextState("생성된 게시물은 삭제되지 않아요")
                }
                
                return .none
                
            case .view(.binding):
                return .none
                
            case .delegate:
                return .none
                
            case .alert(.presented(.confirmWithdrawal)):
                state.isProgressViewPresented = true
                
                return .run { send in
                    let _ = try await accountClient.withdraw()
                    await send(.delegate(.logout))
                } catch: { _, send in
                    
                }
                
            case .alert(_):
                return .none
                
            case .showWithdrawalFailAlert:
                state.alert = AlertState {
                    TextState("계정을 삭제하지 못했어요")
                } actions: {
                    ButtonState(role: .cancel) { TextState("확인") }
                }
                return .none
                
            case .dismissProgressView:
                state.isProgressViewPresented = false
                return .none
            }
        }
        .ifLet(\.$alert, action: \.alert)
    }
}

@ViewAction(for: UserAccountFeature.self)
final class UserAccountViewController: UIViewController {
    
    @UIBindable var store: StoreOf<UserAccountFeature>
    
    private let tableView = UITableView()
    
    private enum Section: Int, CaseIterable {
        case post
        case account

        var title: String {
            switch self {
            case .post: return "게시물 관리"
            case .account: return "계정"
            }
        }
    }
    
    init(store: StoreOf<UserAccountFeature>) {
        self.store = store
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        makeConstraint()
        setupView()
        
        present(item: $store.scope(state: \.alert, action: \.alert)) { store in
            UIAlertController(store: store)
        }
        
        present(isPresented: $store.isProgressViewPresented) {
            ProgressViewController()
        }
    }
    
    private func setupView() {
        view.backgroundColor = .systemBackground
        title = "계정"
        
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")
        tableView.separatorStyle = .none
    }
    
    private func makeConstraint() {
        view.addSubview(tableView)
        
        tableView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
    }
}

// MARK: UITableViewDataSource
extension UserAccountViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return Section.allCases.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let section = Section(rawValue: section) else { return 0 }

        switch section {
        case .post:
            return 1
        case .account:
            return 2 // 로그아웃 + 회원 탈퇴
        }
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return Section(rawValue: section)?.title
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        guard let section = Section(rawValue: indexPath.section) else { return cell }

        switch section {
        case .post:
            cell.textLabel?.text = "내 게시물"
            cell.textLabel?.textColor = .label
        case .account:
            if indexPath.row == 0 {
                cell.textLabel?.text = "로그아웃"
                cell.textLabel?.textColor = .label
            } else if indexPath.row == 1 {
                cell.textLabel?.text = "계정 삭제"
                cell.textLabel?.textColor = .systemRed
            }
        }

        return cell
    }
}

extension UserAccountViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        guard let section = Section(rawValue: indexPath.section) else { return }

        switch section {
        case .post:
            traitCollection.push(state: AccountNavigationStack.Path.State.myPosts(.init()))
        case .account:
            if indexPath.row == 0 {
                send(.logoutButtonTapped)
            } else if indexPath.row == 1 {
                send(.withdrawalButtonTapped)
            }
        }
    }
}

#Preview {
    let store = Store(initialState: UserAccountFeature.State()) {
        UserAccountFeature()
    }
    
    ViewControllerPreview {
        UserAccountViewController(store: store)
    }
}
