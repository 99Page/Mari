//
//  PhotoPreviewController.swift
//  Rim
//
//  Created by 노우영 on 7/17/25.
//

import Foundation
import ComposableArchitecture
import SnapKit
import UIKit
import Core
import SwiftUI

@Reducer
struct PhotoPreviewFeature {
    @ObservableState
    struct State: Equatable {
        @Presents var alert: AlertState<Action.Alert>?
        
        var photoView: RimImageView.State
        var retakeButton = RimLabel.State(text: "다시 찍기", textColor: .white, typography: .primaryAction)
        var usePhotoButton = RimLabel.State(text: "사용하기", textColor: .white, typography: .primaryAction)
        
        init(capturedPhoto: UIImage) {
            self.photoView = .init(image: .uiImage(uiImage: capturedPhoto))
        }
    }
    
    enum Action: ViewAction {
        case view(View)
        case delegate(Delegate)
        case showUsePhotoFailAlert
        case alert(PresentationAction<Alert>)
        
        enum View: BindableAction {
            case retakeButtonTapped
            case useButtonTapped
            case binding(BindingAction<State>)
        }
        
        enum Delegate {
            case usePhoto(UIImage)
            case dismissPhotoView
        }
        
        enum Alert: Equatable {
            case photoErrorConfirm
        }
    }
    
    @Dependency(\.dismiss) var dismiss
    
    var body: some ReducerOf<Self> {
        BindingReducer(action: \.view)
        
        Reduce<State, Action> { state, action in
            switch action {
            case .view(.binding):
                return .none
                
            case .view(.retakeButtonTapped):
                return .run { _ in await dismiss() }
                
            case .view(.useButtonTapped):
                guard case let .uiImage(uiImage) = state.photoView.image else { return .send(.showUsePhotoFailAlert) }
                return .concatenate([
                    .send(.delegate(.usePhoto(uiImage))),
                    .send(.delegate(.dismissPhotoView))
                ])
                
            case .delegate(_):
                return .none
                
            case .showUsePhotoFailAlert:
                state.alert = AlertState {
                    TextState("사진을 사용할 수 없어요")
                } actions: {
                    ButtonState(role: .cancel, action: .photoErrorConfirm) {
                        TextState("확인")
                    }
                }
                return .none
                
            case .alert(.presented(.photoErrorConfirm)):
                return .send(.delegate(.dismissPhotoView))
                
            case .alert:
                return .none
            }
        }
        .ifLet(\.$alert, action: \.alert)
    }
}

@ViewAction(for: PhotoPreviewFeature.self)
class PhotoPreviewController: UIViewController {
    
    @UIBindable var store: StoreOf<PhotoPreviewFeature>
    let photoBackgroundView = UIView()
    let imagePreviewView: RimImageView
    
    
    let stackBackgroundView = UIView()
    let bottomButtonStack = UIStackView()
    let retakeButton: RimLabel
    let usePhotoButton: RimLabel
    
    
    init(store: StoreOf<PhotoPreviewFeature>) {
        @UIBindable var binding = store
        self.store = store
        self.imagePreviewView = RimImageView(state: $binding.photoView)
        self.retakeButton = RimLabel(state: $binding.retakeButton)
        self.usePhotoButton = RimLabel(state: $binding.usePhotoButton)
        super.init(nibName: nil, bundle: nil)
        
        self.modalPresentationStyle = .fullScreen
        self.modalTransitionStyle = .crossDissolve
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override var prefersStatusBarHidden: Bool { true }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
        makeConstraint()
        
        present(item: $store.scope(state: \.alert, action: \.alert)) { store in
            UIAlertController(store: store)
        }
    }
    
    private func makeConstraint() {
        let spacerView = UIView()
        spacerView.setContentHuggingPriority(.defaultLow, for: .horizontal)
        spacerView.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        
        view.addSubview(photoBackgroundView)
        view.addSubview(imagePreviewView)
        view.addSubview(stackBackgroundView)
        stackBackgroundView.addSubview(bottomButtonStack)
        
        bottomButtonStack.addArrangedSubview(retakeButton)
        bottomButtonStack.addArrangedSubview(spacerView)
        bottomButtonStack.addArrangedSubview(usePhotoButton)
        
        photoBackgroundView.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
            make.bottom.equalTo(stackBackgroundView.snp.top)
        }
        
        imagePreviewView.snp.makeConstraints { make in
            make.height.equalTo(view.snp.height).multipliedBy(0.7)
            make.leading.trailing.equalToSuperview()
            make.centerY.equalToSuperview()
        }
        
        stackBackgroundView.snp.makeConstraints { make in
            make.bottom.leading.trailing.equalToSuperview()
        }
        
        bottomButtonStack.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview()
            make.top.equalToSuperview().inset(20)
            make.bottom.equalToSuperview().offset(-64)
        }
    }
    
    private func setupView() {
        view.backgroundColor = .clear
        
        photoBackgroundView.backgroundColor = .black
        stackBackgroundView.backgroundColor = .black
        
        bottomButtonStack.distribution = .fill
        bottomButtonStack.isLayoutMarginsRelativeArrangement = true
        bottomButtonStack.layoutMargins = UIEdgeInsets(top: 0, left: 24, bottom: 0, right: 24)
        
        retakeButton.addAction(.touchUpInside({ [weak self] in
            self?.send(.retakeButtonTapped)
        }), animation: .none)
        
        usePhotoButton.addAction(.touchUpInside({ [weak self] in
            self?.send(.useButtonTapped)
        }), animation: .none)
    }
}

#Preview {
    let store = Store(initialState: PhotoPreviewFeature.State(capturedPhoto: UIImage(resource: .mustafa))) {
        PhotoPreviewFeature()
    }
    
    ViewControllerPreview {
        PhotoPreviewController(store: store)
    }
    .ignoresSafeArea()
}
