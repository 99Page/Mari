//
//  MyPostViewController.swift
//  Rim
//
//  Created by 노우영 on 7/14/25.
//

import Foundation
import ComposableArchitecture
import UIKit

@Reducer
struct MyPostFeature {
    @ObservableState
    struct State {
        var posts: IdentifiedArrayOf<PostSummaryState> = []
        
        // 포스트를 가져오기 위한 커서
        var creationCursor = Date.now
    }
    
    enum Action: ViewAction {
        case fetchMyPosts
        case setPosts(APIResponse<Array<PostDTO>>)
        case view(UIAction)
        
        enum UIAction {
            case viewDidLoad
        }
    }
    
    @Dependency(\.postClient) var postClient
    
    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .view(.viewDidLoad):
                return .send(.fetchMyPosts)
            case .fetchMyPosts:
                return .run { [cursor = state.creationCursor] send in
                    let response = try await postClient.fetchUserPosts(lastCreatedAt: cursor)
                    await send(.setPosts(response))
                }
            case let .setPosts(response):
                
                return .none
            }
        }
    }
}

@ViewAction(for: MyPostFeature.self)
class MyPostViewController: UIViewController {
    let store: StoreOf<MyPostFeature>
    
    init(store: StoreOf<MyPostFeature>) {
        self.store = store
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        send(.viewDidLoad)
    }
}
