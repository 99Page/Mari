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
import SwiftUI
import NMapsMap

@Reducer
struct UploadPostFeature {
    @ObservableState
    struct State: Equatable {
        @Presents var alert: AlertState<AlertAction>?
        @Presents var dismissDialog: ConfirmationDialogState<DialogAction>?
        @Shared(.uid) var uid
        
        let photoLocation: NMGLatLng
        var isProgressViewPresented = false
        var image: RimImageView.State
        var uploadTryCount = 0
        var imageURL: String?
        var description = RimTextView.State(text: "", placeholder: "이곳을 설명해주세요.")
        let maxImageUploadRetry = 3
        
        var postButton = RimLabel.State(
            text: "공유하기",
            textColor: .white,
            appearance: .init(cornerRadius: 25, backgroundColor: UIColor(resource: .main))
        )
        
        var title = RimTextField.State(
            text: "",
            alignment: .left,
            typography: .contentTitle,
            placeholder: "여기는 어떤 곳인가요?",
        )
        
        init(pickedImage: UIImage, photoLocation: NMGLatLng) {
            self.image = RimImageView.State(image: .uiImage(uiImage: pickedImage))
            self.photoLocation = photoLocation
        }
        
        var hasRetryLeft: Bool { uploadTryCount < maxImageUploadRetry }
        var isImageUploaded: Bool { imageURL != nil }
    }
    
    @CasePathable
    enum AlertAction: Equatable {
        case dismissView
        case confirm
    }
    
    @CasePathable 
    enum DialogAction: Equatable {
        case cancel
        case dismiss
    }
    
    enum Action: ViewAction {
        case dismissProgress
        case view(View)
        case dialog(PresentationAction<DialogAction>)
        case delegate(Delegate)
        case uploadImage
        case uploadPost
        case setImageURL(url: String)
        case alert(PresentationAction<AlertAction>)
        case showUploadFailAlert
        case showMissingTitleAlert
        case checkUID
        
        enum View: BindableAction {
            case binding(BindingAction<State>)
            case uploadButtonTapped
            case viewDidLoad
            case xButtonTapped
        }
        
        @CasePathable
        enum Delegate: Equatable {
            case uploadSucceeded
        }
    }
    
    @Dependency(\.postClient) var postClient
    @Dependency(\.imageClient) var imageClient
    @Dependency(\.uuid) var uuid
    @Dependency(\.dismiss) var dismiss
    @Dependency(\.continuousClock) var clock
    
    var body: some ReducerOf<Self> {
        BindingReducer(action: \.view)
        
        Reduce<State, Action> { state, action in
            switch action {
            case .delegate(_):
                return .none
                
            case .view(.xButtonTapped):
                state.dismissDialog = ConfirmationDialogState(titleVisibility: .visible) {
                    TextState("작성 중인 게시글을 삭제할까요?")
                } actions: {
                    ButtonState(role: .destructive, action: .dismiss) {
                        TextState("삭제")
                    }
                    
                    ButtonState(role: .cancel, action: .cancel) {
                        TextState("취소")
                    }
                }
                return .none
                
            case .view(.uploadButtonTapped):
                if !state.isProgressViewPresented {
                    state.isProgressViewPresented = true
                }
                
                if state.isImageUploaded {
                    return .send(.uploadPost)
                } else {
                    return .run { send in
                        for await _ in clock.timer(interval: .seconds(1)) {
                            await send(.view(.uploadButtonTapped))
                        }
                    }
                }
                
            case .view(.binding(_)):
                return .none
                
            case .view(.viewDidLoad):
                return .concatenate(
                    .send(.checkUID),
                    .send(.uploadImage)
                )
                
            case .uploadPost:
                let locationManager = CLLocationManager()
                guard !state.title.text.isEmpty else { return .send(.showMissingTitleAlert) }
                guard let imageURL = state.imageURL else { return .none }
                guard let location = locationManager.location else { return .none }
                guard let uid = state.uid else { return .none }
                
                let request = CreatePostRequest(
                    title: state.title.text,
                    content: state.description.text,
                    latitude: location.coordinate.latitude,
                    longitude: location.coordinate.longitude,
                    creatorID: uid,
                    imageUrl: imageURL
                )
                
                return .run { send in
                    let _ = try await postClient.createPost(request: request)
                    await send(.dismissProgress)
                    await send(.delegate(.uploadSucceeded))
                } catch: { error, send in
                    await send(.showUploadFailAlert)
                }
                
            case .dismissProgress:
                state.isProgressViewPresented = false
                return .none
                
            case .checkUID:
                guard state.uid == nil else { return .none }
                NotificationCenter.default.post(name: .appErrorNotification, object: AppError.emptyUID)
                return .none
                
            case .uploadImage:
                guard state.hasRetryLeft else { return .send(.showUploadFailAlert) }
                guard case let .uiImage(uiImage) = state.image.image else { return .send(.showUploadFailAlert) }
                state.uploadTryCount += 1
                
                return .run { send in
                    let resposne = try await imageClient.uploadImage(image: uiImage, fileName: uuid().uuidString)
                    await send(.setImageURL(url: resposne.imageURL))
                } catch: { error, send in
                    await send(.uploadImage)
                }
                
            case let .setImageURL(url):
                state.imageURL = url
                return .none
                
            case .alert(.presented(.confirm)):
                state.alert = nil
                return .none
                
            case .alert(.presented(.dismissView)):
                return .run { send in
                    await dismiss()
                }
                
            case .alert:
                return .none
                
            case .showUploadFailAlert:
                state.alert = AlertState {
                    TextState("업로드에 실패했어요")
                } actions: {
                    ButtonState(role: .cancel, action: .dismissView) {
                        TextState("확인")
                    }
                }
                return .none
            case .showMissingTitleAlert:
                state.alert = AlertState {
                    TextState("게시글의 제목을 입력해주세요")
                } actions: {
                    ButtonState(role: .cancel, action: .confirm) {
                        TextState("확인")
                    }
                }
                return .none
                
            case .dialog(.presented(.cancel)):
                return .none
                
            case .dialog(.presented(.dismiss)):
                return .run { _ in
                    await dismiss()
                }
                
            case .dialog:
                return .none
            }
        }
        .ifLet(\.$dismissDialog, action: \.dialog)
        .ifLet(\.$alert, action: \.alert)
        .onChange(of: \.isProgressViewPresented) { _, newValue in
            Reduce { state, action in
                state.postButton.isEnabled = !newValue
                return .none
            }
        }
    }
}

@ViewAction(for: UploadPostFeature.self)
class UploadPostViewController: UIViewController {
    
    @UIBindable var store: StoreOf<UploadPostFeature>
    
    private let contentBackgroundView = UIView()
    private let scrollView = UIScrollView(frame: .zero)
    private let photoImage: RimImageView
    private let titleTextField: RimTextField
    private let contentTextView: RimTextView
    private let postButton: RimLabel
    
    init(store: StoreOf<UploadPostFeature>) {
        @UIBindable var binding = store
        
        self.store = store
        self.postButton = RimLabel(state: $binding.postButton)
        self.photoImage = RimImageView(state: $binding.image)
        self.contentTextView = RimTextView(state: $binding.description)
        self.titleTextField = RimTextField(state: $binding.title)
        
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        makeConstraint()
        setupView()
        
        present(item: $store.scope(state: \.alert, action: \.alert)) { store in
            UIAlertController(store: store)
        }
        
        present(item: $store.scope(state: \.dismissDialog, action: \.dialog)) { store in
            UIAlertController(store: store)
        }
        
        present(isPresented: $store.isProgressViewPresented) {
            ProgressViewController()
        }
        
        send(.viewDidLoad)
    }
    
    private func setupView() {
        title = "새 게시물"
        view.backgroundColor = .systemBackground
        
        setupNavigationBar()
        
        scrollView.alwaysBounceVertical = true
        scrollView.contentInset.top = 16
        scrollView.contentInset.bottom = 16 // 스크롤이 올라올 때 텍스트가 잘리는 걸 막습니다. -page, 2025. 07. 11
        
        postButton.addAction(.touchUpInside({ [weak self] in
            self?.send(.uploadButtonTapped)
        }))
        
        contentBackgroundView.addAction(.touchUpInside({ [weak self] in
            self?.view.endEditing(true)
        }), animation: .none)
    }
    
    private func setupNavigationBar() {
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = .systemBackground
        
        appearance.shadowColor = UIColor.lightGray
        
        navigationController?.navigationBar.standardAppearance = appearance
        navigationController?.navigationBar.scrollEdgeAppearance = appearance
        navigationController?.navigationBar.isTranslucent = false
        
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            image: UIImage(systemName: "xmark"),
            style: .plain,
            target: self,
            action: #selector(didTapClose)
        )
        
        navigationItem.leftBarButtonItem?.tintColor = .darkText
    }
    
    @objc private func didTapClose() {
        send(.xButtonTapped)
    }
    
    private func makeConstraint() {
        view.addSubview(contentBackgroundView)
        view.addSubview(postButton)

        contentBackgroundView.addSubview(scrollView)
        scrollView.addSubview(photoImage)
        scrollView.addSubview(titleTextField)
        scrollView.addSubview(contentTextView)
        
        postButton.withKeyboardAvoid(height: 50) { make in
            make.leading.trailing.equalToSuperview().inset(16)
            make.bottom.equalToSuperview().inset(40)
            make.height.equalTo(50)
        }
        
        contentBackgroundView.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
            make.bottom.equalTo(postButton.snp.top)
        }
        
        scrollView.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top)
            make.leading.trailing.top.equalToSuperview()
            make.bottom.equalTo(postButton.snp.top).offset(-16)
        }
        
        photoImage.snp.makeConstraints { make in
            make.top.equalTo(scrollView.contentLayoutGuide.snp.top)
            make.centerX.equalToSuperview()
            make.width.equalToSuperview().multipliedBy(0.6)
            make.height.equalTo(photoImage.snp.width).multipliedBy(4.0 / 3.0)
        }
        
        titleTextField.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(16)
            make.top.equalTo(photoImage.snp.bottom).offset(16)
        }
        
        contentTextView.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(16)
            make.top.equalTo(titleTextField.snp.bottom).offset(16)
            make.bottom.equalTo(scrollView.contentLayoutGuide.snp.bottom)
        }
    }
}

#Preview {
    let image = UIImage(resource: .rimLogo)
    let state = UploadPostNavigationStack.State(pickedImage: image, photoLocation: NMGLatLng(lat: 0, lng: 0))
    let store = Store(initialState: state) {
        UploadPostNavigationStack()
    }
    
    ViewControllerPreview {
        UploadPostStackController(store: store)
    }
    .ignoresSafeArea()
}
