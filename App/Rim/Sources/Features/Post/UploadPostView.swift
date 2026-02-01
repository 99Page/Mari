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
            case onAppear
            case xButtonTapped
        }
        
        @CasePathable
        enum Delegate: Equatable {
            case uploadSucceeded
        }
    }
    
    @Dependency(\.accountClient) var accountClient
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
                state.isProgressViewPresented = true
                
                if state.isImageUploaded {
                    return .send(.uploadPost)
                } else {
                    state.isPendingPostUpload = true
                    return .none
                }
                
            case .view(.binding(_)):
                return .none
                
            case .view(.onAppear):
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
                guard let imageURL = state.imageURL else { return .none }
                
                return .run { [state] send in
                    let request = PostRequest.Create(
                        title: state.title,
                        content: state.descriptionText,
                        latitude: state.photoLocation.lat,
                        longitude: state.photoLocation.lng,
                        imageUrl: imageURL
                    )
                    
                    let _ = try await postClient.createPost(request: request)
                    await send(.dismissProgress)
                    await send(.delegate(.uploadSucceeded))
                } catch: { error, send in
                    if let response = error as? ErrorResponse {
                        await send(.showAlert(title: response.message))
                    } else if let clientError = error as? ClientError,
                              case let .failDecoding(statusCode) = clientError,
                              (200..<300).contains(statusCode) {
                        await send(.dismissProgress)
                        await send(.delegate(.uploadSucceeded))
                    } else {
                        await send(.showAlert(title: "알 수 없는 오류가 발생했습니다."))
                    }
                }
                
            case .dismissProgress:
                state.isProgressViewPresented = false
                return .none
                
            case .checkUID:
                guard state.uid == nil else { return .none }
                accountClient.triggerLogout()
                return .none
                
            case .uploadImage:
                guard state.hasRetryLeft else { return .send(.showUploadFailAlert) }
                guard case let .uiImage(uiImage) = state.image else { return .send(.showUploadFailAlert) }
                state.uploadTryCount += 1
                
                return .run { send in
                    let request = ImageClient.Request.Upload(
                        image: uiImage,
                        path: "photo",
                        fileName: uuid().uuidString,
                        format: .png
                    )
                    let response = try await imageClient.uploadImage(request: request)
                    await send(.setImageURL(url: response.imageURL))
                    await send(.checkPendingPostUpload)
                } catch: { error, send in
                    try? await clock.sleep(for: .seconds(1))
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

    }
}

@ViewAction(for: UploadPostFeature.self)
struct UploadPostView: View {
    @Bindable var store: StoreOf<UploadPostFeature>
    
    // 키보드 내리기 위한 포커스 상태
    @FocusState private var isFocused: Bool
    
    var body: some View {
        ZStack {
            Color(uiColor: .systemBackground).ignoresSafeArea()
            
            VStack(spacing: 0) {
                ScrollView {
                    VStack(spacing: 24) {
                        if case let .uiImage(uiImage) = store.image {
                            Image(uiImage: uiImage)
                                .resizable()
                                .scaledToFill()
                                .frame(maxWidth: .infinity)
                                .aspectRatio(3.0 / 4.0, contentMode: .fit)
                                .containerRelativeFrame(.horizontal) { length, _ in
                                    length * 0.6
                                }
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
                                .padding(.top, 20)
                        }
                        
                        VStack(alignment: .leading, spacing: 16) {
                            TextField(
                                "여기는 어떤 곳인가요?",
                                text: $store.title
                            )
                            .font(size: 20, font: .spoqa(.bold))
                            .focused($isFocused)
                            
                            Divider() //
                            
                            TextField(
                                "더 자세한 내용을 알려주세요.",
                                text: $store.descriptionText,
                                axis: .vertical
                            )
                            .font(size: 16, font: .spoqa(.regular))
                            .focused($isFocused)
                            .frame(minHeight: 120, alignment: .top)
                        }
                        .padding(.horizontal, 20)
                        
                        Spacer()
                        
                        HStack(alignment: .top, spacing: 6) {
                            Image(systemName: "info.circle.fill")
                                .font(.system(size: 12))
                            Text("부적절하거나 불쾌감을 줄 수 있는 게시글은 제재를 받을 수 있습니다.")
                                .font(size: 12, font: .spoqa(.medium))
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .foregroundColor(.gray)
                        .padding(.horizontal, 20)
                        .padding(.bottom, 20)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .scrollDismissesKeyboard(.interactively)
                
                Button {
                    send(.uploadButtonTapped)
                } label: {
                    Text("공유하기")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 54)
                        .background(
                            store.isPostButtonEnabled ? Color(uiColor: .systemBlue) : Color(uiColor: .systemGray4)
                        )
                        .cornerRadius(16)
                }
                .disabled(!store.isPostButtonEnabled)
                .padding(.horizontal, 20)
                .padding(.top, 12)
                .padding(.bottom, 16)
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
            }
        }
        .navigationTitle("새 게시물")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    send(.xButtonTapped)
                } label: {
                    Image(systemName: "xmark")
                        .foregroundColor(.primary)
                        .fontWeight(.semibold)
                }
            }
        }
        .onTapGesture {
            isFocused = false
        }
        .onAppear {
            send(.onAppear)
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
