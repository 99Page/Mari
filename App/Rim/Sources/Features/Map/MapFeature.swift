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
        @Presents var alert: AlertState<Action.Alert>?
        @Presents var uploadPost: UploadPostNavigationStack.State?
        @Presents var camera: CameraFeature.State?
        
        var precision: Geohash.Precision = .seventySixMeters
        
        var posts = IdentifiedArrayOf<MapPostState>()
        var mapCameraCenterPosition = NMGLatLng(lat: 0, lng: 0)
        var photoLocation: NMGLatLng?
        
        var isProgressPresented = false
        
        var selectedFilter = Filter.latest
        var lastFetchPrecision: Int = 7
        
        var visibleBoundes: NMGLatLngBounds?
        var vRadius = 1
        var hRadius = 1
        
        var postsNeedingImages: [MapPostState] {
            return self.posts.filter { $0.image == nil }
        }
        
        mutating func calculateRequestRadius(bounds: NMGLatLngBounds) {
            let gridWidth = precision.gridWidthInMeters
            let gridHeight = precision.gridHeightInMeters
            
            let southWest = bounds.southWest
            let southEast = NMGLatLng(lat: bounds.southWest.lat, lng: bounds.northEast.lng)
            let northWest = NMGLatLng(lat: bounds.northEast.lat, lng: bounds.southWest.lng)
            
            let screenWidthMeters = southWest.distance(to: southEast)
            let screenHeightMeters = southWest.distance(to: northWest)
            
            let halfWidth = screenWidthMeters / 2.0
            let halfHeight = screenHeightMeters / 2.0
            
            let requiredH = ceil(halfWidth / gridWidth)
            let requiredV = ceil(halfHeight / gridHeight)
            
            let hRadius = Int(requiredH) + 1
            let vRadius = Int(requiredV) + 1
            
            self.hRadius = min(hRadius, 8)
            self.vRadius = min(vRadius, 8)
        }
        
        mutating func appropriateGeohashPrecision(bounds: NMGLatLngBounds, density: Double = 3.0) {
            let southWest = bounds.southWest
            let southEast = NMGLatLng(lat: bounds.southWest.lat, lng: bounds.northEast.lng)
            let screenWidthMeters = southWest.distance(to: southEast)
            
            let targetGridSize = screenWidthMeters / density
            
            let precisions: [Geohash.Precision] = [
                .twentyFiveHundredKilometers,
                .sixHundredThirtyKilometers,
                .seventyEightKilometers,
                .twentyKilometers,
                .twentyFourHundredMeters,
                .sixHundredTenMeters,
                .seventySixMeters,
                .nineteenMeters,
                .twoHundredFourtyCentimeters
            ]
            
            for precision in precisions {
                if precision.gridWidthInMeters <= targetGridSize {
                    self.precision = precision
                    return
                }
            }
            
            self.precision = .twoHundredFourtyCentimeters
        }
        
        mutating func updatePosts(from responsePosts: [MapPostDTO]) {
            guard let bounds = self.visibleBoundes else { return }
            
            let center = self.mapCameraCenterPosition
            let visibleRadius = center.distance(to: bounds.southWest)
            let threshold = visibleRadius * 2.0
            
            removePostsOutsideRadius(center: center, threshold: threshold)
            mergeNewPostsWithinRadius(responsePosts, center: center, threshold: threshold)
        }
        
        private mutating func mergeNewPostsWithinRadius(_ newPosts: [MapPostDTO], center: NMGLatLng, threshold: Double) {
            let validPosts = newPosts
                .map { MapPostState(dto: $0) }
                .filter { center.distance(to: $0.nmLocation) <= threshold }
            
            for var post in validPosts {
                if let oldPost = self.posts[id: post.id],
                   let oldImage = oldPost.image,
                   oldPost.imageURL == post.imageURL {
                    // URL이 변경되지 않았다면 기존 이미지 재사용
                    post.image = oldImage
                }
                
                self.posts.updateOrAppend(post)
            }
        }
        
        private mutating func removePostsOutsideRadius(center: NMGLatLng, threshold: Double) {
            self.posts.removeAll { post in
                return center.distance(to: post.nmLocation) > threshold
            }
        }
    }
    
    enum Filter: String {
        case latest
        case popular
    }
    
    enum EffectID {
        case fetchPosts
    }
    
    enum Action: ViewAction {
        case alert(PresentationAction<Alert>)
        case uploadPost(PresentationAction<UploadPostNavigationStack.Action>)
        case camera(PresentationAction<CameraFeature.Action>)
        case view(View)
        case removePost(id: String)
        case fetchPosts
        case setPosts(PostResponse.MapPosts)
        case showFetchFailAlert
        case dismissProgress
        case setImage(postID: String, image: UIImage)
        case showFailedToGetPhotoLocationAlert
        
        enum View: BindableAction {
            case cameraButtonTapped
            case binding(BindingAction<State>)
            case cameraDidMove(centerPosition: NMGLatLng, bounds: NMGLatLngBounds)
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
                state.camera = .init()
                return .none
                
            case let .view(.cameraDidMove(cameraPosition, bounds)):
                state.appropriateGeohashPrecision(bounds: bounds)
                state.calculateRequestRadius(bounds: bounds)
                state.mapCameraCenterPosition = cameraPosition
                state.visibleBoundes = bounds
                
                return .send(.fetchPosts)
                
            case .view(.binding):
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
                
                let postsNeedingImage = state.postsNeedingImages
                
                return .run { send in
                    for post in postsNeedingImage {
                        do {
                            let imageSize = CGSize(width: 80, height: 80)
                            let image = try await imageClient.loadImage(url: post.imageURL, size: imageSize)
                            let markerView = ImageMarkerView(image: Image(uiImage: image), title: post.title)
                            let markerImage = await viewImageGenerator.generate(markerView) ?? UIImage(resource: .placeholder)
                            await send(.setImage(postID: post.id, image: markerImage))
                        } catch {
                            Logger.error("이미지 로드 실패")
                            // 실패 무시 or 처리
                        }
                    }
                }
                
            case let .setImage(postID, image):
                state.posts[id: postID]?.image = image
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
                state.isProgressPresented = true
                
                let request = PostRequest.GetMapPost(
                    type: state.selectedFilter.rawValue,
                    latitude: state.mapCameraCenterPosition.lat,
                    longitude: state.mapCameraCenterPosition.lng,
                    precision: state.precision.rawValue,
                    hRadius: state.hRadius,
                    vRadius: state.vRadius
                )
                
                return .run { send in
                    let response = try await postClient.fetchMapPosts(request: request).result
                    await send(.setPosts(response))
                    await send(.dismissProgress)
                } catch: { error, send in
                    await send(.showFetchFailAlert)
                    await send(.dismissProgress)
                }
                    .debounce(id: EffectID.fetchPosts, for: .seconds(1), scheduler: RunLoop.main)
                
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
        .onChange(of: \.precision) { oldValue, newValue in
            Reduce { _, _ in
                return .send(.fetchPosts)
            }
        }
    }
}

extension Geohash.Precision {
    var gridWidthInMeters: Double {
        switch self {
        case .twentyFiveHundredKilometers: return 5_000_000
        case .sixHundredThirtyKilometers:  return 1_250_000
        case .seventyEightKilometers:      return 156_000
        case .twentyKilometers:            return 39_000
        case .twentyFourHundredMeters:     return 4_900
        case .sixHundredTenMeters:         return 1_200
        case .seventySixMeters:            return 152
        case .nineteenMeters:              return 38
        case .twoHundredFourtyCentimeters: return 4.8
        default: return 0
        }
    }
    
    var gridHeightInMeters: Double {
        switch self {
        case .twentyFiveHundredKilometers: return 5_000_000   // Level 1: 정사각형
        case .sixHundredThirtyKilometers:  return 625_000     // Level 2: 직사각형 (가로의 절반)
        case .seventyEightKilometers:      return 156_000     // Level 3: 정사각형
        case .twentyKilometers:            return 19_500      // Level 4: 직사각형 (가로의 절반)
        case .twentyFourHundredMeters:     return 4_900       // Level 5: 정사각형
        case .sixHundredTenMeters:         return 600         // Level 6: 직사각형 (가로의 절반)
        case .seventySixMeters:            return 152         // Level 7: 정사각형
        case .nineteenMeters:              return 19          // Level 8: 직사각형 (가로의 절반)
        case .twoHundredFourtyCentimeters: return 4.8         // Level 9: 정사각형
        default: return 0
        }
    }
}
