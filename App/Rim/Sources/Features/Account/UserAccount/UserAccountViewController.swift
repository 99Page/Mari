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
            case logoutSucceeded 
        }
    }
    
    @Dependency(\.accountClient) var accountClient
    
    var body: some ReducerOf<Self> {
        Reduce<State, Action> { state, action in
            switch action {
                
            case .view(.logoutButtonTapped):
                return .run { send in
                    try accountClient.logout()
                    
                    await send(.delegate(.logoutSucceeded))
                } catch: { error, send in
                    // 에러 처리
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
    private let items = ["로그아웃"]
    
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
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        cell.textLabel?.text = items[indexPath.row]
        return cell
    }
}

extension UserAccountViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        if indexPath.row == 0 {
            send(.logoutButtonTapped)
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
