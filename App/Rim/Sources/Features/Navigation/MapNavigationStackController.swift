//
//  MapNavigationStackController.swift
//  Rim
//
//  Created by 노우영 on 6/12/25.
//

import Foundation
import ComposableArchitecture
import UIKit

@Reducer
struct MapNavigationStack {
    @Reducer
    enum Path {
        case uploadPost(UploadPostFeature)
        case postDetail(PostDetailFeature)
    }
    
    @ObservableState
    struct State: Equatable {
        var path = StackState<Path.State>()
        var root = MapFeature.State()
    }
    
    enum Action {
        case path(StackActionOf<Path>)
        case root(MapFeature.Action)
    }
    
    var body: some ReducerOf<Self> {
        Scope(state: \.root, action: \.root) {
            MapFeature()
        }
        
        Reduce<State, Action> { state, action in
            switch action {
            case .path(_):
                return .none
            case .root(_):
                return .none
            }
        }
        .forEach(\.path, action: \.path)
    }
}

extension MapNavigationStack.Path.State: Equatable { }

class MapNavigationStackController: NavigationStackController {
    private var store: StoreOf<MapNavigationStack>!
    
    convenience init(store: StoreOf<MapNavigationStack>!) {
        @UIBindable var store = store
        
        self.init(path: $store.scope(state: \.path, action: \.path)) {
            MapViewController(store: store.scope(state: \.root, action: \.root))
        } destination: { store in
            switch store.case {
            case let .uploadPost(store):
                UploadPostViewController(store: store)
            case let .postDetail(store):
                PostDetailViewController(store: store)
            }
        }
        
        self.store = store
    }
}
