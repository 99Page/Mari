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
import CoreLocation
import FirebaseFirestore

@Reducer
struct UploadPostFeature {
    @ObservableState
    struct State {
        var imageURL: String?
        
        var postButton = RimLabel.State(
            text: "공유하기",
            textColor: .white,
            background: .init(color: .systemBlue, cornerRadius: 16)
        )
        
        var contentText = RimTextView.State(
            text: "",
            placeholder: "어떤 이야기를 하고 싶으세요?"
        )
    }
    
    enum Action: ViewAction {
        case view(View)
        case delegate(Delegate)
        
        enum View: BindableAction {
            case binding(BindingAction<State>)
            case uploadButtonTapped
        }
        
        enum Delegate {
            case uploadSucceeded
        }
    }
    
    @Dependency(\.postClient) var postClient
    
    var body: some ReducerOf<Self> {
        BindingReducer(action: \.view)
        
        Reduce<State, Action> { state, action in
            switch action {
            case .delegate(_):
                return .none
                
            case .view(.binding(_)):
                return .none
            case .view(.uploadButtonTapped):
                let locationManager = CLLocationManager()
                
                guard let imageURL = state.imageURL else { return .none }
                guard let location = locationManager.location else { return .none }
                
                let geoPoint = GeoPoint(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude)
                
                let request = PostRequest(
                    content: state.contentText.text,
                    creatorID: UUID().uuidString,
                    imageUrl: imageURL,
                    location: geoPoint,
                    title: "Tmp title"
                )
                
                return .run { send in
                    try await postClient.post(request: request)
                    await send(.delegate(.uploadSucceeded))
                } catch: { error, send in
                    debugPrint("post fail!")
                }
            }
        }
    }
}

@ViewAction(for: UploadPostFeature.self)
class UploadPostViewController: UIViewController {
    
    @UIBindable var store: StoreOf<UploadPostFeature>
    
    let scrollView = UIScrollView(frame: .zero)
    
    let photoImage: RimImageView
    let postButton: RimLabel
    let contentTextView: RimTextView
    
    init(store: StoreOf<UploadPostFeature>) {
        @UIBindable var binding = store
        
        self.store = store
        self.postButton = RimLabel(state: $binding.postButton)
        self.photoImage = RimImageView(imageURL: $binding.imageURL)
        self.contentTextView = RimTextView(state: $binding.contentText)
        
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
        
        postButton.addAction(.touchUpInside({ [weak self] in
            self?.send(.uploadButtonTapped)
        }))
    }
    
    private func send() {
        send(.uploadButtonTapped)
    }
    
    private func configureSubviews() {
        photoImage.configure()
        postButton.configure()
        contentTextView.configure()
    }
    
    private func makeConstraint() {
        view.addSubview(scrollView)
        view.addSubview(postButton)
        
        scrollView.addSubview(photoImage)
        scrollView.addSubview(contentTextView)
        
        postButton.withKeyboardAvoid(height: 50) { make in
            make.leading.trailing.equalToSuperview().inset(16)
            make.bottom.equalToSuperview().inset(32)
            make.height.equalTo(50)
        }
        
        scrollView.snp.makeConstraints { make in
            make.leading.trailing.top.equalToSuperview()
            make.bottom.equalTo(postButton.snp.top).offset(-16)
        }
        
        photoImage.snp.makeConstraints { make in
            make.top.equalToSuperview()
            make.centerX.equalToSuperview()
            make.width.equalTo(200)
            make.height.equalTo(200)
        }
        
        contentTextView.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(16)
            make.top.equalTo(photoImage.snp.bottom).offset(16)
            make.bottom.equalToSuperview()
        }
    }
    
    private func updateView() {
        
    }
}
