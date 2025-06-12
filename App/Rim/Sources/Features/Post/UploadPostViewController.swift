//
//  UploadPostViewController.swift
//  Mari
//
//  Created by 노우영 on 6/11/25.
//

import Foundation
import UIKit
import ComposableArchitecture
import SnapKit
import Core

@Reducer
struct UploadPostFeature {
    @ObservableState
    struct State {
        var imageURL: String
        
        var postButton = RimLabel.State(
            text: "공유하기",
            textColor: .white,
            background: .init(color: .systemBlue, cornerRadius: 16)
        )
    }
    
    enum Action: ViewAction {
        case view(View)
        
        enum View: BindableAction {
            case binding(BindingAction<State>)
        }
    }
    
    var body: some ReducerOf<Self> {
        BindingReducer(action: \.view)
        
        Reduce<State, Action> { state, action in
            switch action {
            case .view(.binding(_)):
                return .none
            }
        }
    }
}

@ViewAction(for: UploadPostFeature.self)
class UploadPostViewController: UIViewController {
    
    @UIBindable var store: StoreOf<UploadPostFeature>
    
    let scrollView = UIScrollView(frame: .zero)
    
    let rimImage: RimImageView
    let postButton: RimLabel
    
    init(store: StoreOf<UploadPostFeature>) {
        @UIBindable var binding = store
        
        self.store = store
        self.postButton = RimLabel(state: $binding.postButton)
        self.rimImage = RimImageView(imageURL: $binding.imageURL)
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        makeConstraint()
        setupView()
        configureSubviews()
    }
    
    private func setupView() {
        title = "포스트 올리기"
        view.backgroundColor = .white
        
        postButton.addAction(.touchUpInside({ debugPrint("button tapped") }))
    }
    
    private func configureSubviews() {
        rimImage.configure()
        postButton.configure()
    }
    
    private func makeConstraint() {
        view.addSubview(scrollView)
        view.addSubview(postButton)
        
        scrollView.addSubview(rimImage)
        
        postButton.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(16)
            make.bottom.equalToSuperview().inset(32)
            make.height.equalTo(50)
        }
        
        scrollView.snp.makeConstraints { make in
            make.leading.trailing.top.equalToSuperview()
            make.bottom.equalTo(postButton.snp.top).inset(16)
        }
        
        rimImage.snp.makeConstraints { make in
            make.top.equalToSuperview()
            make.centerX.equalToSuperview()
            make.width.equalTo(200)
        }
    }
    
    private func updateView() {
        
    }
}
