//
//  MyPostViewController.swift
//  Rim
//
//  Created by 노우영 on 7/14/25.
//

import Foundation
import ComposableArchitecture
import UIKit
import SwiftUI
import Core

@Reducer
struct MyPostFeature {
    @ObservableState
    struct State: Equatable {
        var posts: IdentifiedArrayOf<PostSummaryState> = []
        
        // 포스트를 가져오기 위한 커서
        var creationCursor: Date? = Date.now
    }
    
    enum Action: ViewAction {
        case fetchMyPosts
        case setPosts(FetchUserPostsResponse)
        case view(UIAction)
        
        enum UIAction {
            case didScrollToBottom
            case viewDidLoad
        }
    }
    
    enum EffetcID {
        case fetchPosts
    }
    
    @Dependency(\.postClient) var postClient
    @Dependency(\.mainQueue) var mainQueue
    
    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .view(.didScrollToBottom):
                return .send(.fetchMyPosts)
                
            case .view(.viewDidLoad):
                return .send(.fetchMyPosts)
                
            case .fetchMyPosts:
                guard let cursor = state.creationCursor else { return .none }
                
                return .run { send in
                    let response = try await postClient.fetchUserPosts(lastCreatedAt: cursor).result
                    await send(.setPosts(response))
                }
                .throttle(id: EffetcID.fetchPosts, for: .seconds(1), scheduler: self.mainQueue, latest: false)
                
            case let .setPosts(response):
                let posts = response.posts.map { PostSummaryState(dto: $0) }
                state.posts.append(contentsOf: posts)
//                state.creationCursor = response.nextCursor
                return .none
            }
        }
    }
}

@ViewAction(for: MyPostFeature.self)
class MyPostViewController: UIViewController, UITableViewDataSource {
    let store: StoreOf<MyPostFeature>
    private let tableView = PaginatedTableView()
    
    init(store: StoreOf<MyPostFeature>) {
        self.store = store
        super.init(nibName: nil, bundle: nil)
        hidesBottomBarWhenPushed = true
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        makeConstraint()
        setupView()
        updateView()
        send(.viewDidLoad)
    }
    
    private func setupView() {
        title = "내 게시물"
        
        tableView.dataSource = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")
        tableView.frame = view.bounds
        tableView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        tableView.onScrollToBottom = { [weak self] in
            self?.send(.didScrollToBottom)
        }
    }
    
    private func makeConstraint() {
        view.addSubview(tableView)
    }
    
    private func updateView() {
        observe { [weak self] in
            guard let self else { return }
            let _ = store.posts
            tableView.reloadData()
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        store.posts.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let post = store.posts[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        var content = cell.defaultContentConfiguration()
        content.text = post.title
        cell.contentConfiguration = content
        return cell
    }
}

#Preview {
    let store = Store(initialState: MyPostFeature.State()) {
        MyPostFeature()
            ._printChanges()
    }
    
    ViewControllerPreview {
        MyPostViewController(store: store)
    }
}
