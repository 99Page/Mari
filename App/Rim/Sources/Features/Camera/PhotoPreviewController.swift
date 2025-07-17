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
        var photoView: RimImageView.State
        var retakeButton = RimLabel.State(text: "다시 찍기", textColor: .white, typography: .primaryAction)
        var usePhotoButton = RimLabel.State(text: "사용하기", textColor: .white, typography: .primaryAction)
        
        init(capturedPhoto: UIImage) {
            self.photoView = .init(image: .uiImage(uiImage: capturedPhoto))
        }
    }
    
    enum Action: ViewAction {
        case view(View)
        
        enum View: BindableAction {
            case retakeButtonTapped
            case binding(BindingAction<State>)
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
            }
        }
    }
}

@ViewAction(for: PhotoPreviewFeature.self)
class PhotoPreviewController: UIViewController {
    
    let store: StoreOf<PhotoPreviewFeature>
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
