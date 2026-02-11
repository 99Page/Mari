//
//  MapNavigationStackController.swift
//  Rim
//
//  Created by 노우영 on 6/12/25.
//

import Foundation
import ComposableArchitecture
import UIKit
import Core
import SwiftUI

@Reducer
struct MapNavigationStack {
    @Reducer
    enum Path {
        case postDetail(PostDetailFeature)
        case postList(PostListFeature)
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
            case let .path(.element(id: _, action: .postDetail(.delegate(.removePostFromMap(id))))):
                state.root.posts.remove(id: id)
                return .none
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

class MapNavigationStackController: NavigationStackController, UINavigationControllerDelegate, UIGestureRecognizerDelegate {
    
    private var store: StoreOf<MapNavigationStack>!
    private var swipeInteractionController: SwipeInteractionController?
    
    convenience init(store: StoreOf<MapNavigationStack>!) {
        @UIBindable var store = store
        
        self.init(path: $store.scope(state: \.path, action: \.path)) {
            UIMapViewController(store: store.scope(state: \.root, action: \.root))
        } destination: { store in
            switch store.case {
            case let .postDetail(store):
                PostDetailViewController(store: store)
            case let .postList(store):
                PostListViewController(store: store)
            }
        }
        
        self.store = store
        self.delegate = self
    }
    
    public func navigationController(
        _ navigationController: UINavigationController,
        animationControllerFor operation: UINavigationController.Operation,
        from fromVC: UIViewController,
        to toVC: UIViewController
    ) -> UIViewControllerAnimatedTransitioning? {
        
        if operation == .push {
            self.swipeInteractionController = SwipeInteractionController(viewController: toVC)
        }
        
        if let handler = fromVC as? TransitionHandler {
            print("call!")
            return handler.transitionAnimator(operation: operation, from: fromVC, to: toVC)
        }
        
        if let handler = toVC as? TransitionHandler {
            return handler.transitionAnimator(operation: operation, from: fromVC, to: toVC)
        }
        
        return nil
    }
    
    public func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        return self.viewControllers.count > 1
    }
    
    public func gestureRecognizer(
        _ gestureRecognizer: UIGestureRecognizer,
        shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer
    ) -> Bool {
        return true
    }
    
    public func navigationController(
        _ navigationController: UINavigationController,
        interactionControllerFor animationController: UIViewControllerAnimatedTransitioning
    ) -> UIViewControllerInteractiveTransitioning? {
        guard let controller = swipeInteractionController, controller.interactionInProgress else {
            return nil
        }
        return controller
    }
}
