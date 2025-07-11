//
//  RimTabViewController.swift
//  Rim
//
//  Created by 노우영 on 6/26/25.
//

import UIKit
import ComposableArchitecture

@Reducer
struct TabFeature {
    @ObservableState
    struct State: Equatable {
        var mapStack = MapNavigationStack.State()
        var userAccount = UserAccountFeature.State() 
        
        @Presents var alert: AlertState<AlertAction>?
    }
    
    enum Action: ViewAction {
        case mapStack(MapNavigationStack.Action)
        case userAccount(UserAccountFeature.Action)
        case view(UIAction)
        case alert(PresentationAction<AlertAction>)
        case showRefreshFailAlert
        
        enum UIAction {
            case viewDidLoad
        }
    }
    
    @CasePathable
    enum AlertAction: Equatable {
        case showSignIn
    }
    
    @Dependency(\.continuousClock) var clock
    @Dependency(\.accountClient) var accountClient
    
    var body: some ReducerOf<Self> {
        Scope(state: \.mapStack, action: \.mapStack) {
            MapNavigationStack()
        }
        
        Scope(state: \.userAccount, action: \.userAccount) {
            UserAccountFeature()
        }
        
        Reduce<State, Action> { state, action in
            switch action {
            case .mapStack:
                return .none
            case .userAccount:
                return .none
            case .view(.viewDidLoad):
                return .run { send in
                    // https://firebase.google.com/docs/auth/admin/manage-sessions?utm_source=chatgpt.com&hl=ko
                    // id 토큰은 1시간동안 지속됩니다.
                    // 주기적으로 갱신해야합니다. -page, 2025. 07. 04
                    for await _ in clock.timer(interval: .seconds(60 * 50)) {
                        try await accountClient.refreshIdToken()
                    }
                } catch: { error, send in
                    await send(.showRefreshFailAlert)
                }
                
            case .alert:
                return .none
                
            case .showRefreshFailAlert:
                state.alert = AlertState {
                    TextState("로그인 정보가 만료됐어요")
                } actions: {
                    ButtonState(role: .cancel, action: .showSignIn) {
                        TextState("확인")
                    }
                }
                return .none
            }
        }
        .ifLet(\.$alert, action: \.alert)
    }
}

@ViewAction(for: TabFeature.self)
final class RimTabViewController: UITabBarController {

    @UIBindable var store: StoreOf<TabFeature>
    
    init(store: StoreOf<TabFeature>) {
        self.store = store
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupView()
        buildViewControllers()
        
        send(.viewDidLoad)
        
        present(item: $store.scope(state: \.alert, action: \.alert)) { store in
            UIAlertController(store: store)
        }
    }
    
    private func setupView() {
        view.backgroundColor = .systemBackground
        
        tabBar.isTranslucent = false
        tabBar.backgroundColor = .systemBackground
        tabBar.barTintColor = .systemBackground
        tabBar.scrollEdgeAppearance = tabBar.standardAppearance
    }
    
    private func buildViewControllers() {
        let mapStackStore = store.scope(state: \.mapStack, action: \.mapStack)
        let mapNavigationStackController = MapNavigationStackController(store: mapStackStore)
        let mapImage = UIImage(systemName: "map.fill")
        mapNavigationStackController.tabBarItem = UITabBarItem(title: "지도", image: mapImage, tag: 0)
        
        let userAccountStore = store.scope(state: \.userAccount, action: \.userAccount)
        let userAccountViewController = UserAccountViewController(store: userAccountStore)
        let accountImage = UIImage(systemName: "person.fill")
        userAccountViewController.tabBarItem = UITabBarItem(title: "계정", image: accountImage, tag: 1)

        viewControllers = [mapNavigationStackController, userAccountViewController]
    }
}
