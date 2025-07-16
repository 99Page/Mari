//
//  AccountNavigationController.swift
//  Rim
//
//  Created by 노우영 on 7/14/25.
//

import Foundation
import ComposableArchitecture
import UIKit

@Reducer
struct AccountNavigationStack {
    @ObservableState
    struct State: Equatable {
        var path = StackState<Path.State>()
        var root = UserAccountFeature.State()
    }
    
    enum Action {
        case path(StackActionOf<Path>)
        case root(UserAccountFeature.Action)
    }
    
    @Reducer
    enum Path {
        case myPosts(MyPostFeature)
        case postDetail(PostDetailFeature)
    }
    
    var body: some ReducerOf<Self> {
        Scope(state: \.root, action: \.root) {
            UserAccountFeature()
        }
        
        Reduce<State, Action> { state, action in
            switch action {
            case let .path(.element(id: _, action: .postDetail(.delegate(.removePostFromMyPosts(id))))):
                guard let index = state.path.firstIndex(where: { $0.is(\.myPosts) }) else { return .none}
                let pathID = state.path.ids[index]
                return .send(.path(.element(id: pathID, action: .myPosts(.removePostFromList(id: id)))))
            case .path(_):
                return .none
            case .root:
                return .none
            }
        }
        .forEach(\.path, action: \.path)
    }
}

extension AccountNavigationStack.Path.State: Equatable { }

class AccountNavigationStackController: NavigationStackController {
    private var store: StoreOf<AccountNavigationStack>!
    
    convenience init(store: StoreOf<AccountNavigationStack>!) {
        @UIBindable var store = store
        
        self.init(path: $store.scope(state: \.path, action: \.path)) {
            UserAccountViewController(store: store.scope(state: \.root, action: \.root))
        } destination: { store in
            switch store.case {
            case let .myPosts(store):
                MyPostViewController(store: store)
            case let .postDetail(store):
                PostDetailViewController(store: store)
            }
        }
        
        self.store = store
    }
}
