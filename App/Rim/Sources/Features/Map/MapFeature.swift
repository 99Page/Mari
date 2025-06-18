//
//  MapFeature.swift
//  Mari
//
//  Created by 노우영 on 5/26/25.
//

import Foundation
import ComposableArchitecture
import UIKit

@Reducer
struct MapFeature {
    @ObservableState
    struct State {
        @Presents var alert: AlertState<Action.Alert>?
        @Presents var uploadPost: UploadPostFeature.State?
    }
    
    enum Action: ViewAction {
        case view(View)
        case alert(PresentationAction<Alert>)
        case showImageUploadFailAlert
        case showUploadPost(imageURL: String)
        case uploadPost(PresentationAction<UploadPostFeature.Action>)
        
        enum View: BindableAction {
            case cameraButtonTapped(UIImage)
            case binding(BindingAction<State>)
        }
        
        enum Alert: Equatable {
            
        }
    }
    
    @Dependency(\.imageClient) var imageClient
    
    var body: some ReducerOf<Self> {
        
        BindingReducer(action: \.view)
        
        Reduce<State, Action> { state, action in
            switch action {
                
            case let .view(.cameraButtonTapped(image)):
                return .run { send in
                    debugPrint("upload ongoing...")
                    let response = try await imageClient.uploadImage(image: image, fileName: UUID().uuidString)
                    await send(.showUploadPost(imageURL: response.imageURL))
                } catch: { error, send in
                    await send(.showImageUploadFailAlert)
                }
                
            case .view(.binding(_)):
                return .none
                
            case .uploadPost(_):
                return .none
                
            case .alert:
                return .none
                
            case .showImageUploadFailAlert:
                state.alert = AlertState {
                    TextState("이미지 업로드에 실패했어요.")
                } actions: {
                    ButtonState(role: .cancel) {
                      TextState("확인")
                    }
                }
                return .none
                
            case let .showUploadPost(imageURL):
                state.uploadPost = .init(imageURL: imageURL)
                return .none
            }
        }
        .ifLet(\.$alert, action: \.alert)
        .ifLet(\.$uploadPost, action: \.uploadPost) {
            UploadPostFeature()
        }
        ._printChanges()
    }
}
