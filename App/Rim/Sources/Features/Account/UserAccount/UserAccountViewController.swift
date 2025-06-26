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

@Reducer
struct UserAccountFeature {
    @ObservableState
    struct State {
        
    }
    
    enum Action: ViewAction {
        
        enum UIAction {
            case logoutButtonTapped
        }
    }
    
    var body: some ReducerOf<Self> {
        Reduce<State, Action> { state, action in
            
        }
    }
}

final class UserAccountViewController: UIViewController, UITableViewDataSource {
    
    private let tableView = UITableView()
    private let items = ["Logout"]

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        title = "계정"

        
    }
    
    private func setupView() {
        tableView.dataSource = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")
    }
    
    private func makeConstraint() {
        view.addSubview(tableView)
        
        tableView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
    }

    // MARK: - UITableViewDataSource

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        cell.textLabel?.text = items[indexPath.row]
        return cell
    }
}
