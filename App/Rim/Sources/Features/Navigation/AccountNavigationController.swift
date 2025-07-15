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
    }
    
    var body: some ReducerOf<Self> {
        Scope(state: \.root, action: \.root) {
            UserAccountFeature()
        }
        
        EmptyReducer()
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
            }
        }
        
        self.store = store
    }
}
