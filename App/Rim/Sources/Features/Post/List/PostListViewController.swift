//
//  PostListViewController.swift
//  Rim
//
//  Created by 노우영 on 9/16/25.
//

import Foundation
import SnapKit
import ComposableArchitecture
import UIKit
import Core



@Reducer
struct PostListFeature {
    @ObservableState
    struct State: Equatable {
        @Shared(.blockedUserIds) var blockedUserIds = Set()
        @Presents var postMenu: PostMenuFeature.State?
        
        var posts = IdentifiedArrayOf<PostCell>()
    }
    
    enum Action: ViewAction {
        case view(View)
        case addPostCell(FetchNearPostsResponse)
        case postMenu(PresentationAction<PostMenuFeature.Action>)
        
        enum View: BindableAction {
            case binding(BindingAction<State>)
            case viewDidLoad
            case paginated
            case cellMenuTapped(PostCell)
        }
    }
    
    @Dependency(\.postClient) var postClient
    
    var body: some ReducerOf<Self> {
        BindingReducer(action: \.view)
        
        Reduce<State, Action> { state, action in
            switch action {
            case .view(.binding):
                return .none
            case .view(.viewDidLoad):
                return .run { send in
                    let response = try await postClient.fetchNearPosts()
                    await send(.addPostCell(response.result))
                } catch: { error, send in
                    
                }
                
            case let .view(.cellMenuTapped(post)):
                if post.isMyPost {
                    state.postMenu = .init(menuOption: .myPost)
                } else {
                    state.postMenu = post.isBlokcedPost ? .init(menuOption: .blockedPost) : .init(menuOption: .unblockedPost)
                }
                return .none
                
            case .view(.paginated):
                return .none
                
            case let .addPostCell(response):
                let fetchedPosts = response.posts.map { PostCell(postDetailDTO: $0) }
                state.posts.append(contentsOf: fetchedPosts)
                return .none
                
            case .postMenu:
                return .none
            }
        }
        .ifLet(\.$postMenu, action: \.postMenu) { PostMenuFeature() }
    }
}

@ViewAction(for: PostListFeature.self)
class PostListViewController: UIViewController {
    private let tableView = RimTableView<PostTableViewCell>()
    
    @UIBindable var store: StoreOf<PostListFeature>
    
    init(store: StoreOf<PostListFeature>) {
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
        send(.viewDidLoad)
        
        present(item: $store.scope(state: \.postMenu, action: \.postMenu)) { store in
            PostMenuViewController(store: store)
        }
    }
    
    private func setupView() {
        tableView.items = $store.posts
        tableView.updateView()
        
        tableView.onPaginated { self.send(.paginated) }
        tableView.event = { event in
            switch event {
            case let .menuButtonTapped(post):
                self.send(.cellMenuTapped(post))
            }
        }
    }
    
    private func makeConstraint() {
        view.addSubview(tableView)
        
        tableView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
}

#Preview {
    let store = Store(initialState: PostListFeature.State()) {
        PostListFeature()
    }
    
    PostListViewController(store: store)
}
