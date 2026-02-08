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
import SwiftUI

@Reducer
struct MapFeature {
    @ObservableState
    struct State: Equatable {
        @Shared(.blockedUserIds) var blockedUserIds = Set()
        @Shared(.isLoggedIn) var isLoggedIn = false
        
        @Presents var alert: AlertState<Action.Alert>?
        @Presents var uploadPost: UploadPostNavigationStack.State?
        @Presents var camera: CameraFeature.State?
        @Presents var logIn: LogInFeature.State?
        
        var precision: Geohash.Precision = .seventySixMeters
        var posts = IdentifiedArrayOf<MapPostState>()
        var mapCameraCenterPosition = NMGLatLng(lat: 0, lng: 0)
        var photoLocation: NMGLatLng?
        
        var hasPendingPhotoCapture = false
        var isProgressPresented = false
        
        var selectedFilter = Filter.latest
        var lastFetchPrecision: Int = 7
        
        var visibleBounds: NMGLatLngBounds?
        var zoom = Double(17)
        
        // 마커가 너무 많은 경우, 지도에 제대로 표시되지 않습니다.
        // 네이버 지도에서 공식적으로 어느 기점으로 그런 현상이 나타나는지 공개된 것은 없으며
        // 대략적으로 마커 마커에 사용한 이미지가 40MB를 넘으면 이런 상황이 발생하는 것으로 보입니다.
        // 하지만 이미지의 크기를 세는 것보단, 전체 개수를 제한하는 식으로 마커의 개수를 제한합니다.
        // 축소시킨 이미지의 경우 1MB를 넘지 않습니다.
        private let maxPostCount = 40
        
        // MARK: - Helper Methods
        mutating func updatePosts(from newPosts: [MapPostDTO]) {
            guard let bounds = self.visibleBounds else { return }
            
            let center = self.mapCameraCenterPosition
            let visibleRadius = center.distance(to: bounds.southWest)
            let threshold = visibleRadius * 2.0
            
            mergePosts(newPosts: newPosts, center: center, threshold: threshold)
            cleanPosts()
        }
        
        private mutating func cleanPosts() {
            if posts.count < maxPostCount { return }
            
            performDistanceCleanup()
            performPrecisionCleanup()
        }
        
        private mutating func performPrecisionCleanup() {
            var idsToRemove: [String] = []
            let currentPrecision = precision
            
            for post in self.posts {
                if posts.count < maxPostCount { break }
                
                if post.fetchedPrecision != currentPrecision {
                    idsToRemove.append(post.id)
                }
            }
            for id in idsToRemove {
                self.posts.remove(id: id)
            }
        }
        
        private mutating func performDistanceCleanup() {
            guard let bounds = visibleBounds else { return }
            
            var idsToRemove: [String] = []
            
            let center = self.mapCameraCenterPosition
            let visibleRadius = center.distance(to: bounds.southWest)
            let threshold = visibleRadius * 2.0 // 화면 반경의 2배
            
            for post in self.posts {
                if posts.count <= maxPostCount { break }
                
                if center.distance(to: post.nmLocation) > threshold {
                    idsToRemove.append(post.id)
                }
            }
            
            for id in idsToRemove {
                posts.remove(id: id)
            }
        }
        
        private mutating func mergePosts(newPosts: [MapPostDTO], center: NMGLatLng, threshold: Double) {
            let currentPrecision = self.precision
            
            for dto in newPosts {
                let dtoLocation = NMGLatLng(lat: dto.location.latitude, lng: dto.location.longitude)
                if center.distance(to: dtoLocation) > threshold { continue }
                
                if var existingPost = self.posts[id: dto.id] {
                    existingPost = MapPostState(dto: dto, fetchedPrecision: currentPrecision)
                    self.posts.updateOrAppend(existingPost)
                    
                } else {
                    let newPost = MapPostState(dto: dto, fetchedPrecision: currentPrecision)
                    self.posts.append(newPost)
                }
            }
        }
    }
    
    enum Filter: String {
        case latest
        case popular
    }
    
    enum EffectID {
        case fetchPosts
        case cancelImageLoad
    }
    
    enum Action: ViewAction {
        case alert(PresentationAction<Alert>)
        case uploadPost(PresentationAction<UploadPostNavigationStack.Action>)
        case camera(PresentationAction<CameraFeature.Action>)
        case logIn(PresentationAction<LogInFeature.Action>)
        case view(View)
        case removePost(id: String)
        case fetchPosts
        case setPosts(PostResponse.MapPosts)
        case showFetchFailAlert
        case dismissProgress
        case showFailedToGetPhotoLocationAlert
        case setLoadingIndicator(Bool)
        
        enum View: BindableAction {
            case cameraButtonTapped
            case binding(BindingAction<State>)
            case cameraDidMove(centerPosition: NMGLatLng, bounds: NMGLatLngBounds, zoom: Double)
        }
        
        enum Alert: Equatable {
            case openLocationSettings
        }
    }
    
    @Dependency(\.imageClient) var imageClient
    @Dependency(\.postClient) var postClient
    @Dependency(\.locationManager) var locationManager
    @Dependency(\.viewImageGenerator) var viewImageGenerator
    
    var body: some ReducerOf<Self> {
        BindingReducer(action: \.view)
            .onChange(of: \.selectedFilter) { oldValue, newValue in
                Reduce { state, action in
                    return .send(.fetchPosts)
                }
            }
        
        Reduce<State, Action> { state, action in
            switch action {
            case .view(.cameraButtonTapped):
                state.hasPendingPhotoCapture = true
                
                if state.isLoggedIn {
                    state.camera = .init()
                } else {
                    state.logIn = .init(message: "로그인하면 게시글을 올릴 수 있어요")
                }
                
                return .none
                
            case let .view(.cameraDidMove(cameraPosition, bounds, zoom)):
                state.mapCameraCenterPosition = cameraPosition
                state.visibleBounds = bounds
                state.zoom = zoom
                return .send(.fetchPosts)
                
            case .view(.binding):
                return .none
                
            case let .setLoadingIndicator(value):
                state.isProgressPresented = value
                return .none
                
            case let .camera(.presented(.photoPreview(.presented(.delegate(.usePhoto(image)))))):
                guard let photoLocation = state.photoLocation else { return .none }
                state.uploadPost = .init(pickedImage: image, photoLocation: photoLocation)
                return .none
                
            case .camera(.presented(.delegate(.photoCaptured))):
                let currentLocation = try? locationManager.getCurrentLocation()
                
                if let currentLocation {
                    state.photoLocation = NMGLatLng(lat: currentLocation.coordinate.latitude, lng: currentLocation.coordinate.longitude)
                } else {
                    state.photoLocation = nil
                }
                return .none
                
            case let .logIn(.presented(.delegate(delegateAction))):
                switch delegateAction {
                case .logInSucceeded:
                    if state.hasPendingPhotoCapture {
                        state.hasPendingPhotoCapture = false
                        state.camera = .init()
                    }
                    return .none
                    
                case .logInFailed:
                    if state.hasPendingPhotoCapture {
                        state.hasPendingPhotoCapture = false
                    }
                    return .none
                }
                
            case .logIn:
                return .none
                
            case .camera:
                return .none
                
            case .uploadPost(.presented(.root(.delegate(.uploadSucceeded)))):
                state.uploadPost = nil
                
                return state.selectedFilter == .latest ? .send(.fetchPosts) : .none
                
            case .uploadPost(_):
                return .none
                
            case .alert(.presented(.openLocationSettings)):
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
                return .none
                
            case .alert:
                return .none
                
            case let .setPosts(response):
                state.updatePosts(from: response.posts)
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
                
            case .dismissProgress:
                state.isProgressPresented = false
                return .none
                
            case .fetchPosts:
                
                return .run { [center = state.mapCameraCenterPosition, zoom = state.zoom] send in
                    await send(.setLoadingIndicator(true))
                    
                    let request = PostRequest.GetMapPost(
                        latitude: center.lat,
                        longitude: center.lng,
                        zoom: Int(zoom)
                    )
                    
                    let response = try await postClient.fetchMapPosts(request: request).result
                    await send(.setPosts(response))
                    await send(.dismissProgress)
                    await send(.setLoadingIndicator(false))
                } catch: { error, send in
                    await send(.showFetchFailAlert)
                    await send(.dismissProgress)
                    await send(.setLoadingIndicator(false))
                }
                    .debounce(id: EffectID.fetchPosts, for: .seconds(1), scheduler: DispatchQueue.main)
                    .cancellable(id: EffectID.fetchPosts, cancelInFlight: true)
                
            case let .removePost(id):
                state.posts.remove(id: id)
                return .none
                
            case .showFailedToGetPhotoLocationAlert:
                state.alert = AlertState {
                    TextState("현재 위치를 확인할 수 없어요")
                } actions: {
                    ButtonState(action: .openLocationSettings) {
                        TextState("설정으로 이동")
                    }
                }
                
                return .none
            }
        }
        .ifLet(\.$alert, action: \.alert)
        .ifLet(\.$uploadPost, action: \.uploadPost) { UploadPostNavigationStack() }
        .ifLet(\.$camera, action: \.camera) { CameraFeature() }
        .ifLet(\.$logIn, action: \.logIn) { LogInFeature() }
    }
}
