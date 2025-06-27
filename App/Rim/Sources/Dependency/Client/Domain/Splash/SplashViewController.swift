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

@Reducer
struct SplashFeature {
    @ObservableState
    struct State {
        // ChatGPT가 내부 로고만 있는 svg 파일을 제대로 생성해주지 못해서 png 사용
        // -page 2025. 06. 27
        var logo = RimImageView.State(image: .resource(imageResource: .rimLogo))
        
        var appName = RimLabel.State(text: "Rim", textColor: .white, typography: .logoTitle)
        var appDescription = RimLabel.State(text: "지금, 우리 동네 이야기", textColor: .white, typography: .logoDescription)
    }
    
    enum Action: ViewAction {
        case view(UIAction)
        
        @CasePathable
        enum UIAction: BindableAction {
            case viewDidLoad
            case binding(BindingAction<State>)
        }
    }
    
    var body: some ReducerOf<Self> {
        BindingReducer(action: \.view)
        
        Reduce<State, Action> { state, action in
            switch action {
            case .view:
                return .none
            }
        }
    }
}

@ViewAction(for: SplashFeature.self)
class SplashViewController: UIViewController {
    
    let store: StoreOf<SplashFeature>
    
    let contentView = UIView()
    
    let logoImageView: RimImageView
    let appNameLabel: RimLabel
    let appDescriptionlabel: RimLabel
    
    init(store: StoreOf<SplashFeature>) {
        @UIBindable var binding = store
        self.store = store
        self.logoImageView = RimImageView(state: $binding.logo)
        self.appNameLabel = RimLabel(state: $binding.appName)
        self.appDescriptionlabel = RimLabel(state: $binding.appDescription)
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupView()
        makeConstraint()
        configureSubview()
    }
    
    private func configureSubview() {
        logoImageView.configure()
        appNameLabel.configure()
        appDescriptionlabel.configure()
    }
    
    private func setupView() {
        view.backgroundColor = UIColor(resource: .main)
    }
    
    private func makeConstraint() {
        view.addSubview(contentView)
        
        contentView.addSubview(logoImageView)
        contentView.addSubview(appNameLabel)
        contentView.addSubview(appDescriptionlabel)
        
        contentView.addSubview
        
        logoImageView.snp.makeConstraints { make in
            make.centerX.centerY.equalToSuperview()
            make.width.height.equalTo(250)
        }
        
        appNameLabel.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalTo(logoImageView.snp.bottom).offset(16)
        }
        
        appDescriptionlabel.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalTo(appNameLabel.snp.bottom).offset(16)
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
