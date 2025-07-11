//
//  RootViewController.swift
//  Rim
//
//  Created by 노우영 on 7/11/25.
//

import Foundation
import ComposableArchitecture
import UIKit
import Core

@Reducer
struct RootFeature {
    @ObservableState
    struct State: Equatable {
        @Shared(.uid) var uid
        @Presents var alert: AlertState<AlertAction>?
        var destination: Destination.State = .splash(.init())
    }
    
    @Reducer
    enum Destination {
        case splash(SplashFeature)
        case signIn(SignInFeature)
        case tab(TabFeature)
    }
    
    @CasePathable
    enum AlertAction: Equatable {
        case signOut
    }
    
    enum Action: ViewAction {
        case changeState(to: Destination.State)
        case view(UIAction)
        case signOut
        case destination(Destination.Action)
        case handleError(AppError)
        case alert(PresentationAction<AlertAction>)
        
        enum UIAction: BindableAction {
            case binding(BindingAction<State>)
            case viewDidLoad
        }
    }
    
    @Dependency(\.accountClient) var accountClient
    @Dependency(\.continuousClock) var clock
    @Dependency(\.appErrorStream) var appErrorStream
    
    var body: some ReducerOf<Self> {
        BindingReducer(action: \.view)
        
        // https://github.com/pointfreeco/swift-composable-architecture/discussions/1296#discussioncomment-3487107
        Scope(state: \.destination, action: \.destination) {
            EmptyReducer()
                .ifLet(\.signIn, action: \.signIn) { SignInFeature() }
                .ifLet(\.splash, action: \.splash) { SplashFeature() }
                .ifLet(\.tab, action: \.tab) { TabFeature() }
        }
        
        Reduce<State, Action> { state, action in
            switch action {
            case .view(.viewDidLoad):
                return .run { send in
                    for await error in await appErrorStream.stream() {
                        await send(.handleError(error))
                    }
                }
                
            case .view(_):
                return .none
                
            case let .handleError(error):
                switch error {
                case .emptyUID:
                    state.alert = AlertState {
                        TextState("사용자 정보가 없어요")
                    } actions: {
                        ButtonState(role: .cancel, action: .signOut) {
                            TextState("로그아웃")
                        }
                    }
                    return .none
                }
                
            case .destination(.signIn(.delegate(.signInSucceeded))):
                state.destination = .tab(.init())
                return .none
                
            case .destination(.signIn(_)):
                return .none
                
            case .destination(.tab(.userAccount(.delegate(.logout)))):
                return .send(.signOut)
                
            case .destination(.tab(.alert(.presented(.showSignIn)))):
                return .send(.signOut)
                
            case .destination(.tab(_)):
                return .none
                
            case .signOut:
                do {
                    try accountClient.logout()
                    state.destination = .signIn(.init())
                    state.$uid.withLock { $0 = nil }
                } catch {
                    Logger.error("키체인 에러", category: .auth)
                }
                
                return .none
                
            case .destination(.splash(.delegate(.showTab))):
                return .run { send in
                    // 지연없이 바로 상태를 변경하면 observe { } 에서 제대로 관찰하지 못합니다. -page 2025. 06. 27
                    try await clock.sleep(for: .seconds(1))
                    await send(.changeState(to: .tab(.init())))
                }
                
            case .destination(.splash(.delegate(.showSignIn))):
                return .run { send in
                    // 지연없이 바로 상태를 변경하면 observe { } 에서 제대로 관찰하지 못합니다. -page 2025. 06. 27
                    try await clock.sleep(for: .seconds(1))
                    await send(.changeState(to: .signIn(.init())))
                }
                
            case let .changeState(value):
                state.destination = value
                return .none
                
            case .destination(_):
                return .none
                
            case .alert(.presented(.signOut)):
                return .send(.signOut)
                
            case .alert(_):
                return .none
            }
        }
    }
}

@ViewAction(for: RootFeature.self)
class RootViewController: UIViewController {
    
    @UIBindable var store: StoreOf<RootFeature>
    private var current: UIViewController?
    
    init(store: StoreOf<RootFeature>) {
        self.store = store
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        updateView()
        send(.viewDidLoad)
        
        present(item: $store.scope(state: \.alert, action: \.alert)) { store in
            UIAlertController(store: store)
        }
    }
    
    private func updateView() {
        observe { [weak self] in
            guard let self else { return }
            
            // store의 모든 상태를 읽고 있기때문에, 아래 과정들은 반복 호출됩니다.
            // 현재 뷰컨트롤러와 비교하는 과정이 필요합니다. -page 2025. 06. 26
            switch store.state.destination {
            case .signIn:
                if let signInStore = store.scope(state: \.destination.signIn, action: \.destination.signIn) {
                    let signInVC = SignInViewController(store: signInStore)
                    transition(to: signInVC)
                }
            case .tab:
                if let tabStore = store.scope(state: \.destination.tab, action: \.destination.tab) {
                    let tabVC = RimTabViewController(store: tabStore)
                    transition(to: tabVC)
                }
            case .splash:
                if let splashStore = store.scope(state: \.destination.splash, action: \.destination.splash) {
                    let splashVC = SplashViewController(store: splashStore)
                    transition(to: splashVC)
                }
            }
        }
    }
    
    func transition<T: UIViewController>(to new: T, animated: Bool = true) {
        guard !isRootViewController(ofType: T.self) else { return }
        
        if let current {
            // 현재 child 제거
            current.willMove(toParent: nil)
            current.view.removeFromSuperview()
            current.removeFromParent()
        }

        // 새로운 child 추가
        addChild(new)
        view.addSubview(new.view)
        new.view.frame = view.bounds
        new.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        new.didMove(toParent: self)
        
        self.current = new
    }
    
    private func isRootViewController<T: UIViewController>(ofType type: T.Type) -> Bool {
        return current is T
    }
}

extension RootFeature.Destination.State: Equatable {
    
}
