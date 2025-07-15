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
        @Presents var alert: AlertState<AlertAction>?
        var posts: IdentifiedArrayOf<PostSummaryState> = []
        
        // 포스트를 가져오기 위한 커서
        var creationCursor: Date? = Date.now
    }
    
    enum Table {
        
    }
    
    @CasePathable
    enum AlertAction: Equatable {
        case deletePost(PostSummaryState)
    }
    
    enum Action: ViewAction {
        case removePostFromList(id: String)
        case fetchMyPosts
        case appendPosts(FetchUserPostsResponse)
        case view(UIAction)
        case alert(PresentationAction<AlertAction>)
        case showDeleteConfirmAlert(PostSummaryState)
        case showFetchFailAlert
        case showDeleteFailAlert
        
        enum UIAction: BindableAction {
            case binding(BindingAction<State>)
            case deleteButtonTapped(PostSummaryState)
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
        BindingReducer(action: \.view)
        
        Reduce { state, action in
            switch action {
            case .view(.binding):
                return .none
                
            case let .view(.deleteButtonTapped(post)):
                return .send(.showDeleteConfirmAlert(post))
                
            case .view(.didScrollToBottom):
                return .send(.fetchMyPosts)
                
            case .view(.viewDidLoad):
                return .send(.fetchMyPosts)
                
            case .fetchMyPosts:
                guard let cursor = state.creationCursor else { return .none }
                
                return .run { send in
                    let response = try await postClient.fetchUserPosts(lastCreatedAt: cursor).result
                    await send(.appendPosts(response))
                } catch: { _, send in
                    await send(.showFetchFailAlert)
                }
                .throttle(id: EffetcID.fetchPosts, for: .seconds(1), scheduler: self.mainQueue, latest: false)
                
            case .showDeleteFailAlert:
                state.alert = AlertState {
                    TextState("게시물을 삭제하지 못했어요")
                } actions: {
                    ButtonState(role: .cancel) {
                        TextState("확인")
                    }
                }
                return .none
                
            case .showFetchFailAlert:
                state.creationCursor = nil
                
                state.alert = AlertState {
                    TextState("게시물을 가져오지 못했어요")
                } actions: {
                    ButtonState(role: .cancel) {
                        TextState("확인")
                    }
                }
                return .none
                
            case let .showDeleteConfirmAlert(post):
                state.alert = AlertState {
                    TextState("게시물을 삭제할까요?")
                } actions: {
                    ButtonState(role: .destructive, action: .deletePost(post)) {
                        TextState("삭제")
                    }
                    
                    ButtonState(role: .cancel) {
                        TextState("취소")
                    }
                }
                
                return .none
                
            case let .appendPosts(response):
                let posts = response.posts.map { PostSummaryState(dto: $0) }
                state.posts.append(contentsOf: posts)
                state.creationCursor = response.nextCursor
                return .none
                
            case let .alert(.presented(.deletePost(post))):
                return .run { send in
                    let response = try await postClient.deletePost(postID: post.id)
                    await send(.removePostFromList(id: response.result.id))
                } catch: { _, send in
                    await send(.showDeleteFailAlert)
                }
                
            case .alert:
                return .none
                
            case let .removePostFromList(id):
                state.posts.remove(id: id)
                return .none
            }
        }
        .ifLet(\.$alert, action: \.alert)
        ._printChanges()
    }
}

@ViewAction(for: MyPostFeature.self)
class MyPostViewController: UIViewController {
    
    enum Section {
        case main
    }

    private var dataSource: UITableViewDiffableDataSource<Section, PostSummaryState>!
    
    @UIBindable var store: StoreOf<MyPostFeature>
    private let tableView = PaginatedTableView()
    private var previousTintColor: UIColor?
    
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
        
        present(item: $store.scope(state: \.alert, action: \.alert)) { store in
            UIAlertController(store: store)
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        previousTintColor = navigationController?.navigationBar.tintColor
        navigationController?.navigationBar.tintColor = .black
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.navigationBar.tintColor = previousTintColor
    }
    
    private func setupView() {
        title = "내 게시물"
        
        tableView.delegate = self
        tableView.onScrollToBottom = { [weak self] in
            self?.send(.didScrollToBottom)
        }
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")
        tableView.frame = view.bounds
        tableView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        
        setupDataSource()
    }
    
    private func makeConstraint() {
        view.addSubview(tableView)
    }
    
    private func updateView() {
        observe { [weak self] in
            guard let self else { return }
            var snapshot = NSDiffableDataSourceSnapshot<Section, PostSummaryState>()
            snapshot.appendSections([.main])
            snapshot.appendItems(store.posts.elements, toSection: .main)
            dataSource.apply(snapshot, animatingDifferences: true)
        }
    }
    
    private func setupDataSource() {
        dataSource = UITableViewDiffableDataSource<Section, PostSummaryState>(tableView: tableView) { tableView, indexPath, post in
            let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
            var content = cell.defaultContentConfiguration()
            content.text = post.title
            cell.contentConfiguration = content
            return cell
        }
    }
}

extension MyPostViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let deleteAction = UIContextualAction(style: .destructive, title: "삭제") { [weak self] _, _, completionHandler in
            guard let self else { return }
            let post = store.posts[indexPath.row]
            send(.deleteButtonTapped(post))
            completionHandler(true)
        }
        
        return UISwipeActionsConfiguration(actions: [deleteAction])
    }
    
    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let post = store.posts[indexPath.row]
        let postDetail = PostDetailFeature.State(postID: post.id)
        traitCollection.push(state: AccountNavigationStack.Path.State.postDetail(postDetail))
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
