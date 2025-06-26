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
    struct State {
        var mapStack = MapNavigationStack.State()
    }
    
    enum Action: ViewAction {
        case mapStack(MapNavigationStack.Action)
        case view(UIAction)
        
        enum UIAction { }
    }
    
    var body: some ReducerOf<Self> {
        Scope(state: \.mapStack, action: \.mapStack) {
            MapNavigationStack()
        }
        
        Reduce<State, Action> { state, action in
            switch action {
            case .mapStack:
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

        let mapStackStore = store.scope(state: \.mapStack, action: \.mapStack)
        let mapNavigationStackController = MapNavigationStackController(store: mapStackStore)
        mapNavigationStackController.tabBarItem = UITabBarItem(title: "Map", image: UIImage(systemName: "map.fill"), tag: 0)

        viewControllers = [mapNavigationStackController]
    }
}
