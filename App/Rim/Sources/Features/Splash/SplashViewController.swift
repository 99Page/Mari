//
//  SplashViewController.swift
//  Rim
//
//  Created by 노우영 on 6/27/25.
//

import Foundation
import ComposableArchitecture
import SnapKit
import SwiftUI
import UIKit
import Core
import FirebaseAuth

@Reducer
struct SplashFeature {
    @ObservableState
    struct State: Equatable {
        // ChatGPT가 내부 로고만 있는 svg 파일을 제대로 생성해주지 못해서 png 사용
        // -page 2025. 06. 27
        var logo = RimImageView.State(image: .resource(imageResource: .rimWithBackground))
    }
    
    enum Action: ViewAction {
        case view(UIAction)
        case delegate(Delegate)
        
        @CasePathable
        enum UIAction: BindableAction {
            case viewDidLoad
            case binding(BindingAction<State>)
        }
        
        @CasePathable
        enum Delegate {
            case loggedIn
            case loggedOut
        }
    }
    
    @Dependency(\.accountClient) var accountClient
    
    var body: some ReducerOf<Self> {
        BindingReducer(action: \.view)
        
        Reduce<State, Action> { state, action in
            switch action {
            case .view(.viewDidLoad):
                let isLoggedIn = accountClient.isLoggedIn()
                return .run { send in
                    isLoggedIn ? await send(.delegate(.loggedIn)) : await send(.delegate(.loggedOut))
                }
            case .view(.binding):
                return .none
            case .delegate:
                return .none
            }
        }
    }
}

@ViewAction(for: SplashFeature.self)
class SplashViewController: UIViewController {
    
    let store: StoreOf<SplashFeature>
    
    let logoImageView: RimImageView
    
    init(store: StoreOf<SplashFeature>) {
        @UIBindable var binding = store
        self.store = store
        self.logoImageView = RimImageView(state: $binding.logo)
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupView()
        makeConstraint()
        
        send(.viewDidLoad)
    }
    
    private func setupView() {
        view.backgroundColor = UIColor(resource: .main)
    }
    
    private func makeConstraint() {
        view.addSubview(logoImageView)
        
        logoImageView.snp.makeConstraints { make in
            make.centerX.centerY.equalToSuperview()
            make.width.height.equalTo(150)
        }
    }
}

#Preview {
    let store = Store(initialState: SplashFeature.State()) {
        SplashFeature()
    }
    
    ViewControllerPreview {
        SplashViewController(store: store)
    }
    .ignoresSafeArea()
}
