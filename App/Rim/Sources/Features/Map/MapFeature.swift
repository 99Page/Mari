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
import NMapsMap
import Geohash

@Reducer
struct MapFeature {
    @ObservableState
    struct State: Equatable {
        @Presents var alert: AlertState<Action.Alert>?
        @Presents var uploadPost: UploadPostFeature.State?
        
        // 기본 줌 레벨 14
        // 줌 레벨의 최대값 22, 최솟값은 약 0.67
        // 값이 커질수록 확대됩니다 -page, 2025. 07. 04
        var zoomLevel: Double = 17.0
        
        var posts: [PostSummaryState] = []
        var retrievedGeoHashes: Set<String> = []
        var centerPosition = NMGLatLng(lat: 0, lng: 0)
        
        var latestFilter = RimLabel.State(text: "최신순", textColor: .black)
        var latestBackground = RimView.State(
            borderColor: UIColor(resource: .main),
            borderWidth: 1.2,
            cornerRadius: 13,
            backgroundColor: .white,
            shadowColor: .clear,
            shadowOpacity: 0.9,
            shadowOffset: CGSize(width: -2, height: 2),
            shadowRadius: 2
        )
        
        var popularFilter = RimLabel.State(text: "인기순",textColor: .black)
        var popularBackground = RimView.State(
            borderWidth: 1.2,
            cornerRadius: 13,
            backgroundColor: .white,
            shadowColor: .gray,
            shadowOpacity: 0.9,
            shadowOffset: CGSize(width: -2, height: 2),
            shadowRadius: 2
        )
        
        var selectedFilter = Filter.latest
        
        var precision: Geohash.Precision {
            switch zoomLevel {
            case ..<15:
                return .sixHundredTenMeters  // 0~14
            case 15..<18:
                return .seventySixMeters // 15~17
            default:
                return .nineteenMeters // 17 이상
            }
        }
    }
    
    enum Filter: String {
        case latest
        case popular
    }
    
    enum DebounceID {
        case fetchPosts
    }
    
    enum Action: ViewAction {
        case fetchPosts
        case setPosts(FetchNearPostsResponse)
        case view(UIAction)
        case alert(PresentationAction<Alert>)
        case showImageUploadFailAlert
        case showFetchFailAlert
        case showUploadPost(imageURL: String)
        case uploadPost(PresentationAction<UploadPostFeature.Action>)
        
        enum UIAction: BindableAction {
            case cameraButtonTapped(UIImage)
            case binding(BindingAction<State>)
            case cameraDidMove(zoomLevel: Double, centerPosition: NMGLatLng)
        }
        
        enum Alert: Equatable {
            
        }
    }
    
    @Dependency(\.imageClient) var imageClient
    @Dependency(\.postClient) var postClient
    
    var body: some ReducerOf<Self> {
        
        BindingReducer(action: \.view)
            .onChange(of: \.selectedFilter) { oldValue, newValue in
                Reduce { state, action in
                    return .send(.fetchPosts)
                }
            }
        
        Reduce<State, Action> { state, action in
            switch action {
                
            case let .view(.cameraButtonTapped(image)):
                return .run { send in
                    let response = try await imageClient.uploadImage(image: image, fileName: UUID().uuidString)
                    await send(.showUploadPost(imageURL: response.imageURL))
                } catch: { error, send in
                    await send(.showImageUploadFailAlert)
                }
                
            case let .view(.cameraDidMove(zoomLevel, cameraPosition)):
                let centerGeoHash = Geohash.encode(latitude: cameraPosition.lat, longitude: cameraPosition.lng, precision: state.precision)
                
                guard !state.retrievedGeoHashes.contains(centerGeoHash) else { return .none}
                
                state.zoomLevel = zoomLevel
                state.centerPosition = cameraPosition
                
                return .send(.fetchPosts)
                
            case .view(.binding(.set(\.selectedFilter, .latest))):
                state.latestBackground.borderColor = UIColor(resource: .main)
                state.latestBackground.shadowColor = .clear
                
                state.popularBackground.shadowColor = .gray
                state.popularBackground.borderColor = .clear
                
                let generator = UIImpactFeedbackGenerator(style: .light)
                generator.prepare()
                generator.impactOccurred()
                return .none
                
            case .view(.binding(.set(\.selectedFilter, .popular))):
                state.latestBackground.borderColor = .clear
                state.latestBackground.shadowColor = .gray
                
                state.popularBackground.shadowColor = .clear
                state.popularBackground.borderColor = UIColor(resource: .main)
                
                let generator = UIImpactFeedbackGenerator(style: .light)
                generator.prepare()
                generator.impactOccurred()
                return .none
                
            case .view(.binding):
                return .none
                
            case .uploadPost(.presented(.delegate(.uploadSucceeded))):
                state.uploadPost = nil
                return .send(.fetchPosts)
                
            case .uploadPost(_):
                return .none
                
            case .alert:
                return .none
                
            case .showImageUploadFailAlert:
                state.alert = AlertState {
                    TextState("이미지 업로드에 실패했어요")
                } actions: {
                    ButtonState(role: .cancel) {
                      TextState("확인")
                    }
                }
                return .none
                
            case let .showUploadPost(imageURL):
                state.uploadPost = .init(imageURL: imageURL)
                return .none
                
            case let .setPosts(response):
                state.posts = response.posts.map { PostSummaryState(dto: $0) }
                state.retrievedGeoHashes = Set(response.geohashBlocks)
                return .none
                
            case .showFetchFailAlert:
                state.alert = AlertState {
                    TextState("주위 정보를 가져오지 못했어요")
                } actions: {
                    ButtonState(role: .cancel) {
                      TextState("확인")
                    }
                }
                return .none
                
            case .fetchPosts:
                let lat = state.centerPosition.lat
                let lng = state.centerPosition.lng
                
                let request = FetchNearPostsRequest(
                    type: state.selectedFilter.rawValue,
                    latitude: lat,
                    longitude: lng,
                    precision: state.precision.rawValue
                )
                
                return .run { send in
                    let response = try await postClient.fetchNearPosts(request)
                    await send(.setPosts(response))
                } catch: { error, send in
                    await send(.showFetchFailAlert)
                }
                    .debounce(id: DebounceID.fetchPosts, for: .seconds(1), scheduler: RunLoop.main)
            }
        }
        .ifLet(\.$alert, action: \.alert)
        .ifLet(\.$uploadPost, action: \.uploadPost) {
            UploadPostFeature()
        }
    }
}

