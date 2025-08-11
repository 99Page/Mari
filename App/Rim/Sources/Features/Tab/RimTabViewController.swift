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
        @Shared(.hasAgreedToEULA) var hasAgreedToEULA = false
        
        var mapStack = MapNavigationStack.State()
        var userAccountStack = AccountNavigationStack.State()
        
        @Presents var alert: AlertState<Action.Alert>?
    }
    
    enum Action: ViewAction {
        case delegate(Delegate)
        case mapStack(MapNavigationStack.Action)
        case userAccountStack(AccountNavigationStack.Action)
        case view(View)
        case alert(PresentationAction<Alert>)
        case showRefreshFailAlert
        
        @CasePathable
        enum View {
            case viewDidLoad
        }
        
        @CasePathable
        enum Delegate {
            case signOut
        }
        
        @CasePathable
        enum Alert: Equatable {
            case showSignIn
            case agreeToEULA
            case disagreeToEULA
        }
    }
    
    @Dependency(\.continuousClock) var clock
    @Dependency(\.accountClient) var accountClient
    
    var body: some ReducerOf<Self> {
        Scope(state: \.mapStack, action: \.mapStack) {
            MapNavigationStack()
        }
        
        Scope(state: \.userAccountStack, action: \.userAccountStack) {
            AccountNavigationStack()
        }
        
        Reduce<State, Action> { state, action in
            switch action {
            case let .userAccountStack(.path(.element(id: _, action: .myPosts(.delegate(.removePostFromMap(id)))))):
                return .send(.mapStack(.root(.removePost(id: id))))
                
            case let .userAccountStack(.path(.element(id: _, action: .postDetail(.delegate(.removePostFromMap(id)))))):
                return .send(.mapStack(.root(.removePost(id: id))))
                
            case .mapStack:
                return .none
                
            case .userAccountStack:
                return .none
                
            case .view(.viewDidLoad):
                if !state.$hasAgreedToEULA.wrappedValue {
                    state.alert = .eula
                }
                
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
                
            case .alert(.presented(.agreeToEULA)):
                state.$hasAgreedToEULA.withLock {
                    $0 = true
                }
                
                return .none
                
            case .alert(.presented(.disagreeToEULA)):
                return .send(.delegate(.signOut))
                
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
                
            case .delegate(_):
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
        
        let accountStackStore = store.scope(state: \.userAccountStack, action: \.userAccountStack)
        let accountNavigationController = AccountNavigationStackController(store: accountStackStore)
        let accountImage = UIImage(systemName: "person.fill")
        accountNavigationController.tabBarItem = UITabBarItem(title: "계정", image: accountImage, tag: 1)

        viewControllers = [mapNavigationStackController, accountNavigationController]
    }
}

private extension AlertState where Action == TabFeature.Action.Alert {
    static let eula = AlertState {
        TextState("최종 사용자 사용권 계약 (EULA)")
    } actions: {
        ButtonState(role: .destructive, action: .disagreeToEULA) {
            TextState("거부")
        }
        
        ButtonState(role: .cancel, action: .agreeToEULA) {
            TextState("동의")
        }
    } message: {
        TextState(
            """
            1. 본 서비스는 불쾌하거나 부적절한 콘텐츠를 허용하지 않습니다.
            2. 사용자는 다른 사용자의 콘텐츠를 신고하거나 해당 사용자를 차단할 수 있습니다.
            3. 신고된 콘텐츠와 사용자를 검토 후 적절히 조치합니다.
            4. 이용자는 본 약관에 동의해야 서비스를 사용할 수 있습니다.
            """
        )
    }
}
