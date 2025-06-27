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
    enum State: Equatable {
        case splash(SplashFeature.State)
        case login(LoginFeature.State)
        case tab(TabFeature.State)
    }
    
    enum Action: ViewAction {
        case changeState(to: SceneFeature.State)
        case view(UIAction)
        case login(LoginFeature.Action)
        case tab(TabFeature.Action)
        case splash(SplashFeature.Action)
        
        enum UIAction: BindableAction {
            case binding(BindingAction<State>)
        }
    }
    
    @Dependency(\.continuousClock) var clock
    
    var body: some ReducerOf<Self> {
        BindingReducer(action: \.view)
        
        Scope(state: \.login, action: \.login) {
            LoginFeature()
        }
        
        Scope(state: \.tab, action: \.tab) {
            TabFeature()
        }
        
        Scope(state: \.splash, action: \.splash) {
            SplashFeature()
        }
        
        Reduce<State, Action> { state, action in
            switch action {
            case .view(_):
                return .none
                
            case .login(.delegate(.signInSucceeded)):
                state = .tab(.init())
                return .none
                
            case .login(_):
                return .none
                
            case .tab(.userAccount(.delegate(.logoutSucceeded))):
                state = .login(.init())
                return .none
                
            case .tab(_):
                return .none
                
            case .splash(.delegate(.loggedIn)):
                return .run { send in
                    // 지연없이 바로 상태를 변경하면 observe { } 에서 제대로 관찰하지 못합니다. -page 2025. 06. 27
                    try await clock.sleep(for: .seconds(1))
                    await send(.changeState(to: .tab(.init())))
                }
                
            case .splash(.delegate(.loggedOut)):
                return .run { send in
                    // 지연없이 바로 상태를 변경하면 observe { } 에서 제대로 관찰하지 못합니다. -page 2025. 06. 27
                    try await clock.sleep(for: .seconds(1))
                    await send(.changeState(to: .login(.init())))
                }
                
            case .splash:
                return .none
                
            case let .changeState(value):
                state = value
                return .none
            }
        }
        ._printChanges()
    }
}

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    let store = Store(initialState: SceneFeature.State.splash(.init())) {
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
            
            // store의 모든 상태를 읽고 있기때문에, 아래 과정들은 반복 호출됩니다.
            // 따라서 현재 뷰컨트롤러와 비교하는 과정이 필요합니다. -page 2025. 06. 26
            switch store.state {
            case .login:
                if let loginStore = store.scope(state: \.login, action: \.login) {
                    let loginVC = LoginViewController(store: loginStore)
                    selectViewController(viewController: loginVC)
                }
            case .tab:
                if let tabStore = store.scope(state: \.tab, action: \.tab) {
                    let tabVC = RimTabViewController(store: tabStore)
                    selectViewController(viewController: tabVC)
                }
            case .splash:
                if let splashStore = store.scope(state: \.splash, action: \.splash) {
                    let splashVC = SplashViewController(store: splashStore)
                    selectViewController(viewController: splashVC)
                }
            }
        }
    }
    
    private func selectViewController<T: UIViewController>(viewController: T) {
        guard !isRootViewController(ofType: T.self) else { return }
        window?.rootViewController = viewController
    }
    
    private func isRootViewController<T: UIViewController>(ofType type: T.Type) -> Bool {
        return window?.rootViewController is T
    }
}
