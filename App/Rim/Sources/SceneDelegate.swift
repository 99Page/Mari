//
//  SceneDelegate.swift
//  Mari
//
//  Created by 노우영 on 5/26/25.
//

import Foundation
import UIKit
import ComposableArchitecture

@Reducer
struct SceneFeature {
    @ObservableState
    enum State {
        case login(LoginFeature.State)
        case map(MapNavigationStack.State)
    }
    
    enum Action: ViewAction {
        case view(UIAction)
        case login(LoginFeature.Action)
        case map(MapNavigationStack.Action)
        
        enum UIAction: BindableAction {
            case binding(BindingAction<State>)
        }
    }
    
    var body: some ReducerOf<Self> {
        BindingReducer(action: \.view)
        
        Scope(state: \.login, action: \.login) {
            LoginFeature()
        }
        
        Scope(state: \.map, action: \.map) {
            MapNavigationStack()
        }
        
        Reduce<State, Action> { state, action in
            switch action {
            case .view(_):
                return .none
            case .login(.delegate(.signInSucceeded)):
                state = .map(.init())
                return .none
            case .login(_):
                return .none
            case .map(_):
                return .none
            }
        }
        ._printChanges()
    }
}

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    let store = Store(initialState: SceneFeature.State.login(.init())) {
        SceneFeature()
    }
    
    var window: UIWindow?

    func scene(_ scene: UIScene,
               willConnectTo session: UISceneSession,
               options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = (scene as? UIWindowScene) else { return }

        let window = UIWindow(windowScene: windowScene)
        window.makeKeyAndVisible()
        self.window = window
        selectView()
    }
    
    private func selectView() {
        observe { [weak self] in
            guard let self else { return }
            
            switch store.state {
            case .login:
                selectLoginViewController()
            case .map:
                selectMapNaivgationStackController()
            }
        }
    }
    
    private func selectLoginViewController() {
        guard let loginStore = store.scope(state: \.login, action: \.login) else { return }
        guard !isRootViewController(ofType: LoginViewController.self) else { return }
        let loginVC = LoginViewController(store: loginStore)
        window?.rootViewController = loginVC
    }
    
    private func selectMapNaivgationStackController() {
        guard let mapStore = store.scope(state: \.map, action: \.map) else { return }
        guard !isRootViewController(ofType: MapNavigationStackController.self) else { return }
        let mapNavigationStack = MapNavigationStackController(store: mapStore)
        window?.rootViewController = mapNavigationStack
    }
    
    private func isRootViewController<T: UIViewController>(ofType type: T.Type) -> Bool {
        return window?.rootViewController is T
    }
}
