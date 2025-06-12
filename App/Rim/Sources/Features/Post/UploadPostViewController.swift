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
    
    init(store: StoreOf<UploadPostFeature>) {
        @UIBindable var binding = store
        self.store = store
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
    }
    
    private func configureSubviews() {
        rimImage.configure()
    }
    
    private func makeConstraint() {
        view.addSubview(scrollView)
        
        scrollView.addSubview(rimImage)
        
        scrollView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
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
