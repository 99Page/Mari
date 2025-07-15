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
        @Shared(.uid) var uid
    }
    
    enum Action: ViewAction {
        case view(UIAction)
        case delegate(Delegate)
        
        @CasePathable
        enum UIAction {
            case logoutButtonTapped
        }
        
        @CasePathable
        enum Delegate {
            case logout
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
                
            case .delegate:
                return .none
            }
        }
    }
}

@ViewAction(for: UserAccountFeature.self)
final class UserAccountViewController: UIViewController {
    
    let store: StoreOf<UserAccountFeature>
    
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
    }
    
    private func setupView() {
        view.backgroundColor = .systemBackground
        title = "계정"
        
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")
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
            return 0 // 포스트 관련 항목 아직 없음
        case .account:
            return 1 // 로그아웃 버튼
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
            cell.addAction(.touchUpInside({ [weak self] in
                
            }))
            cell.textLabel?.text = ""
        case .account:
            cell.textLabel?.text = "로그아웃"
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
            break
        case .account:
            if indexPath.row == 0 {
                send(.logoutButtonTapped)
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
