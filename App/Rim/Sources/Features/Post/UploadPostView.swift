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
        var image: RimImageView.ImageType
        var uploadTryCount = 0
        var imageURL: String?
        
        var descriptionText = ""
        let maxImageUploadRetry = 3
        
        var isPostButtonEnabled = true
        var isPendingPostUpload = false
        
        var postButton = RimLabel.State(
            appearance: .init(cornerRadius: 25, backgroundColor: UIColor(resource: .main))
        )
        
        var title = ""
        
        init(pickedImage: UIImage, photoLocation: NMGLatLng) {
            self.image = .uiImage(uiImage: pickedImage)
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
        case uploadMarkerImage(image: UIImage, title: String)
        case uploadImage
        case uploadPost
        case setImageURL(url: String)
        case alert(PresentationAction<AlertAction>)
        case showUploadFailAlert
        case showMissingTitleAlert
        case showAlert(title: String)
        case checkUID
        case checkPendingPostUpload
        
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
    @Dependency(\.viewImageGenerator) var viewImageGenerator
    
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
                state.isProgressViewPresented = true
                
                if state.isImageUploaded {
                    return .send(.uploadPost)
                } else {
                    state.isPendingPostUpload = true
                    return .none
                }
                
            case .view(.binding(_)):
                return .none
                
            case .view(.viewDidLoad):
                return .concatenate(
                    .send(.checkUID),
                    .send(.uploadImage)
                )
                
            case .checkPendingPostUpload:
                guard state.isPendingPostUpload else { return .none }
                state.isPendingPostUpload = false
                return .send(.uploadPost)
                
            case .uploadPost:
                guard !state.title.isEmpty else { return .send(.showMissingTitleAlert) }
                
                guard case let .uiImage(uiImage) = state.image else { return .none }
                guard let imageURL = state.imageURL else { return .none }
                
                guard let uid = state.uid else { return .none }
                
           
                return .run { [state] send in
                    let image = Image(uiImage: uiImage)
                    let view = ImageMarkerView(image: image, title: state.title)
                    
                    guard let viewImage = await viewImageGenerator.generate(view) else { return }
                    let id = uuid().uuidString
                    
                    let imageParam = ImageClient.UploadImageParameter(
                        image: viewImage,
                        path: "marker",
                        fileName: id,
                        format: .png
                    )
                    
                    let response = try await imageClient.uploadImage(imageParam)
                    
                    let request = PostRequest.Post(
                        title: state.title,
                        content: state.descriptionText,
                        latitude: state.photoLocation.lat,
                        longitude: state.photoLocation.lng,
                        creatorID: uid,
                        imageUrl: imageURL,
                        markerUrl: response.imageURL
                    )
                    
                    let _ = try await postClient.createPost(request: request)
                    await send(.dismissProgress)
                    await send(.delegate(.uploadSucceeded))
                } catch: { error, send in
                    if let response = error as? ErrorResponse {
                        await send(.showAlert(title: response.message))
                    } 
                }
                
            case .dismissProgress:
                state.isProgressViewPresented = false
                return .none
                
            case .checkUID:
                guard state.uid == nil else { return .none }
                NotificationCenter.default.post(name: .appErrorNotification, object: AppError.emptyUID)
                return .none
                
            case let .uploadMarkerImage(uiImage, title):
                let image = Image(uiImage: uiImage)
                let view = ImageMarkerView(image: image, title: title)
                
                return .run { send in
                    guard let viewImage = await viewImageGenerator.generate(view) else { return }
                    let id = uuid().uuidString
                    
                    let param = ImageClient.UploadImageParameter(
                        image: viewImage,
                        path: "marker",
                        fileName: id,
                        format: .png
                    )
                    
                    let response = try await imageClient.uploadImage(param)
                }
                
            case .uploadImage:
                guard state.hasRetryLeft else { return .send(.showUploadFailAlert) }
                guard case let .uiImage(uiImage) = state.image else { return .send(.showUploadFailAlert) }
                state.uploadTryCount += 1
                
                return .run { send in
                    let param = ImageClient.UploadImageParameter(
                        image: uiImage,
                        path: "photo",
                        fileName: uuid().uuidString,
                        format: .png
                    )
                    let response = try await imageClient.uploadImage(param: param)
                    await send(.setImageURL(url: response.imageURL))
                    await send(.checkPendingPostUpload)
                } catch: { error, send in
                    await send(.uploadImage)
                }
                
            case let .showAlert(title):
                state.alert = AlertState {
                    TextState(title)
                } actions: {
                    ButtonState(role: .cancel, action: .confirm) {
                        TextState("확인")
                    }
                }
                return .none
                
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
                state.isProgressViewPresented = false
                
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
                state.isPostButtonEnabled = !newValue
                return .none
            }
        }
        ._printChanges()
    }
}

@ViewAction(for: UploadPostFeature.self)
struct UploadPostView: View {
    @Bindable var store: StoreOf<UploadPostFeature>
    
    // 키보드 내리기 위한 포커스 상태
    @FocusState private var isFocused: Bool
    
    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                ScrollView {
                    VStack(spacing: 16) {
                        if case let .uiImage(uiImage) = store.image {
                            Image(uiImage: uiImage)
                                .resizable()
                                .scaledToFill()
                                .frame(maxWidth: .infinity)
                                .aspectRatio(3.0 / 4.0, contentMode: .fit)
                                .containerRelativeFrame(.horizontal) { length, _ in
                                    length * 0.6
                                }
                                .clipped()
                        }
                        
                        TextField(
                            "여기는 어떤 곳인가요?",
                            text: $store.title
                        )
                        .font(.headline)
                        .multilineTextAlignment(.leading)
                        .focused($isFocused)
                        .padding(.horizontal, 16)

                        TextField(
                            "더 자세한 내용을 알려주세요.",
                            text: $store.descriptionText,
                            axis: .vertical
                        )
                        .focused($isFocused)
                        .padding(.horizontal, 16)

                        Text("부적절하거나 불쾌감을 줄 수 있는 게시글은 제재를 받을 수 있습니다.")
                            .font(.caption)
                            .foregroundColor(.gray)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 16)
                            .padding(.top, 4)
                    }
                    .padding(.vertical, 16)
                }
                .scrollDismissesKeyboard(.interactively)
                
                Button {
                    send(.uploadButtonTapped)
                } label: {
                    Text("공유하기")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(
                            store.isPostButtonEnabled ? Color(uiColor: .systemBlue) : Color.gray
                        )
                        .cornerRadius(25)
                }
                .disabled(!store.isPostButtonEnabled)
                .padding(.horizontal, 16)
                .padding(.bottom, 16) // Safe Area 고려
            }
            
            if store.isProgressViewPresented {
                Color.black.opacity(0.4)
                    .ignoresSafeArea()
                    .overlay {
                        ProgressView()
                            .progressViewStyle(.circular)
                            .tint(.white)
                            .scaleEffect(1.5)
                    }
                    .onTapGesture {
                        
                    }
            }
        }
        .navigationTitle("새 게시물")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            // X 버튼 (닫기)
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    send(.xButtonTapped)
                } label: {
                    Image(systemName: "xmark")
                        .foregroundColor(.black)
                }
            }
        }
        .onTapGesture {
            isFocused = false
        }
        .onAppear {
            send(.viewDidLoad)
        }
        .alert($store.scope(state: \.alert, action: \.alert))
        .confirmationDialog($store.scope(state: \.dismissDialog, action: \.dialog))
    }
}

#Preview {
    let image = UIImage(resource: .rimLogo)
    let state = UploadPostNavigationStack.State(pickedImage: image, photoLocation: NMGLatLng(lat: 0, lng: 0))
    let store = Store(initialState: state) {
        UploadPostNavigationStack()
    }
    
    UploadPostStackController(store: store)
}
