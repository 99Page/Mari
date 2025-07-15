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
        case postDetail(PostDetailFeature)
    }
    
    @ObservableState
    struct State: Equatable {
        var path: StackState<Path.State>
        var root: MapFeature.State
        
        init(path: StackState<Path.State> = StackState<Path.State>(), root: MapFeature.State = MapFeature.State()) {
            self.path = path
            self.root = root
        }
        
        /// PostDetailViewController 프리뷰를 위한 이니셜라이저입니다.
        /// 프리뷰에서 MapNvigationStack.Path.State가 추론되지 않아 추가했습니다.
        init(postDetail: PostDetailFeature.State) {
            self.path = .init([.postDetail(postDetail)])
            self.root = MapFeature.State()
        }
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
            case let .postDetail(store):
                PostDetailViewController(store: store)
            }
        }
        
        self.store = store
    }
}
