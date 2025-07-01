//
//  MapFeature.swift
//  Mari
//
//  Created by 노우영 on 5/26/25.
//

import Foundation
import ComposableArchitecture
import UIKit
import Core
import CoreLocation

@Reducer
struct MapFeature {
    @ObservableState
    struct State: Equatable {
        @Presents var alert: AlertState<Action.Alert>?
        @Presents var uploadPost: UploadPostFeature.State?
        
        // 기본 줌 레벨 14
        // 줌 레벨의 최대값 22, 최솟값은 약 0.67
        var zoomLevel: Double = 14.0
        var posts: [PostSummaryState] = []
        
        var precision: Double {
            if zoomLevel <= 14 {
                return 6
            } else {
                return 6
            }
        }
    }
    
    enum Action: ViewAction {
        case setPosts([PostSummaryState])
        case view(UIAction)
        case alert(PresentationAction<Alert>)
        case showImageUploadFailAlert
        case showUploadPost(imageURL: String)
        case uploadPost(PresentationAction<UploadPostFeature.Action>)
        
        enum UIAction: BindableAction {
            case cameraButtonTapped(UIImage)
            case binding(BindingAction<State>)
            case viewDidLoad
        }
        
        enum Alert: Equatable {
            
        }
    }
    
    @Dependency(\.imageClient) var imageClient
    @Dependency(\.postClient) var postClient
    
    var body: some ReducerOf<Self> {
        
        BindingReducer(action: \.view)
        
        Reduce<State, Action> { state, action in
            switch action {
                
            case let .view(.cameraButtonTapped(image)):
                return .run { send in
                    let response = try await imageClient.uploadImage(image: image, fileName: UUID().uuidString)
                    await send(.showUploadPost(imageURL: response.imageURL))
                } catch: { error, send in
                    await send(.showImageUploadFailAlert)
                }
                
            case .view(.viewDidLoad):
                let locationManager = CLLocationManager()
                guard let location = locationManager.location else { return .none }
                
                let request = FetchNearPostsRequest(
                    latitude: location.coordinate.latitude,
                    longitude: location.coordinate.longitude,
                    precision: state.precision
                )
                
                return .run { send in
                    let response = try await postClient.fetchNearPosts(request)
                    let posts = response.map { PostSummaryState(dto: $0) }
                    await send(.setPosts(posts))
                } catch: { error, send in
                    debugPrint("fetch fail")
                }
                
            case .view(.binding(_)):
                return .none
                
            case .uploadPost(.presented(.delegate(.uploadSucceeded))):
                state.uploadPost = nil
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
                
            case let .setPosts(posts):
                state.posts = posts
                return .none
            }
        }
        .ifLet(\.$alert, action: \.alert)
        .ifLet(\.$uploadPost, action: \.uploadPost) {
            UploadPostFeature()
        }
    }
}
