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
    }
    
    enum Action: ViewAction {
        case mapStack(MapNavigationStack.Action)
        case userAccount(UserAccountFeature.Action)
        case view(UIAction)
        
        enum UIAction { }
    }
    
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
            case .view:
                return .none
            }
        }
    }
}

@ViewAction(for: TabFeature.self)
final class RimTabViewController: UITabBarController {

    let store: StoreOf<TabFeature>
    
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
    }
    
    private func setupView() {
        view.backgroundColor = .systemBackground
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
