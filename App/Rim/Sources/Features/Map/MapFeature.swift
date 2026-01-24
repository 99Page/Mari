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
        
        var visibleBounds: NMGLatLngBounds?
        var vRadius = 1
        var hRadius = 1
        
        var postsNeedingImages: [MapPostState] {
            return self.posts.filter { $0.image == nil }
        }
        
        mutating func optimizeGeohashState(bounds: NMGLatLngBounds) {
            let (screenWidth, screenHeight) = calculateScreenSizeInMeters(bounds: bounds)
            
            let maxRadiusLimit = 2
            
            self.precision = determineBestPrecision(
                screenWidth: screenWidth,
                screenHeight: screenHeight,
                maxRadiusLimit: maxRadiusLimit
            )
            
            updateRequestRadius(
                screenWidth: screenWidth,
                screenHeight: screenHeight
            )
        }
        
        // MARK: - Helper Methods
        
        /// 화면 크기를 미터 단위로 계산
        private func calculateScreenSizeInMeters(bounds: NMGLatLngBounds) -> (width: Double, height: Double) {
            let southWest = bounds.southWest
            let southEast = NMGLatLng(lat: bounds.southWest.lat, lng: bounds.northEast.lng)
            let northWest = NMGLatLng(lat: bounds.northEast.lat, lng: bounds.southWest.lng)
            
            let width = southWest.distance(to: southEast)
            let height = southWest.distance(to: northWest)
            
            return (width, height)
        }
        
        /// 주어진 예산(Limit) 내에서 사용할 수 있는 가장 높은 Precision 반환
        private func determineBestPrecision(screenWidth: Double, screenHeight: Double, maxRadiusLimit: Int) -> Geohash.Precision {
            // 검사 순서: 가장 정밀한 것(P9) -> 가장 넓은 것(P1)
            let precisions: [Geohash.Precision] = [
                .twoHundredFourtyCentimeters,
                .nineteenMeters,
                .seventySixMeters,
                .sixHundredTenMeters,
                .twentyFourHundredMeters,
                .twentyKilometers,
                .seventyEightKilometers,
                .sixHundredThirtyKilometers,
                .twentyFiveHundredKilometers
            ]
            
            let halfWidth = screenWidth / 2.0
            let halfHeight = screenHeight / 2.0
            
            for precision in precisions {
                let gridW = precision.gridWidthInMeters
                let gridH = precision.gridHeightInMeters
                
                // 이 Precision일 때 필요한 칸 수 계산
                let requiredH = Int(ceil(halfWidth / gridW))
                let requiredV = Int(ceil(halfHeight / gridH))
                
                // 예산 범위 안에 들어오면 즉시 당첨 (가장 높은 정밀도부터 돌기 때문)
                if requiredH <= maxRadiusLimit && requiredV <= maxRadiusLimit {
                    return precision
                }
            }
            
            // 예산으로 커버 불가능한 거대 영역(지구 전체 뷰 등)인 경우 최후의 수단
            return .twentyFiveHundredKilometers
        }
        
        /// 현재 설정된 Precision을 기준으로 hRadius, vRadius를 업데이트
        private mutating func updateRequestRadius(screenWidth: Double, screenHeight: Double) {
            let gridW = self.precision.gridWidthInMeters
            let gridH = self.precision.gridHeightInMeters
            
            let halfWidth = screenWidth / 2.0
            let halfHeight = screenHeight / 2.0
            
            let requiredH = Int(ceil(halfWidth / gridW))
            let requiredV = Int(ceil(halfHeight / gridH))
            
            // 최소 1칸은 보장 (화면 모서리 잘림 방지)
            self.hRadius = max(1, requiredH)
            self.vRadius = max(1, requiredV)
            
            // 로그 확인용 (필요시 주석 해제)
            // print("✅ 최적화: P\(self.precision.rawValue), h:\(self.hRadius), v:\(self.vRadius)")
        }
        
        mutating func updatePosts(from newPosts: [MapPostDTO]) {
            guard let bounds = self.visibleBounds else { return }
            
            let center = self.mapCameraCenterPosition
            let visibleRadius = center.distance(to: bounds.southWest)
            let threshold = visibleRadius * 2.0
            
            mergePosts(newPosts: newPosts, center: center, threshold: threshold)
            cleanPosts()
        }
        
        private mutating func cleanPosts() {
            
            let limitMB: Double = 40
            
            var currentTotalSize = self.posts.reduce(0) { total, post in
                return total + (post.image?.memorySizeInMB ?? 0)
            }
            
            if currentTotalSize <= limitMB { return }
            
            performDistanceCleanup(limitMB: limitMB, currentTotalSize: &currentTotalSize)
            performPrecisionCleanup(limitMB: limitMB, currentTotalSize: &currentTotalSize)
        }
        
        private mutating func performPrecisionCleanup(
            limitMB: Double,
            currentTotalSize: inout Double,
        ) {
            guard currentTotalSize > limitMB else { return }
            
            var idsToRemove: [String] = []
            
            let currentPrecision = precision
            
            for post in self.posts {
                if currentTotalSize <= limitMB { break }
                
                if post.fetchedPrecision != currentPrecision {
                    currentTotalSize -= post.image?.memorySizeInMB ?? 0
                    idsToRemove.append(post.id)
                }
            }
            for id in idsToRemove {
                self.posts.remove(id: id)
            }
        }
        
        private mutating func performDistanceCleanup(
            limitMB: Double,
            currentTotalSize: inout Double,
        ) {
            guard let bounds = visibleBounds else { return }
            
            var idsToRemove: [String] = []
            
            let center = self.mapCameraCenterPosition
            let visibleRadius = center.distance(to: bounds.southWest)
            let threshold = visibleRadius * 2.0 // 화면 반경의 2배
            
            for post in self.posts {
                if currentTotalSize <= limitMB { break }
                
                if center.distance(to: post.nmLocation) > threshold {
                    currentTotalSize -= post.image?.memorySizeInMB ?? 0
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
                    let oldImage = existingPost.image
                    let oldImageURL = existingPost.imageURL
                    
                    existingPost = MapPostState(dto: dto, fetchedPrecision: currentPrecision)
                    
                    if oldImageURL == dto.imageUrl {
                        existingPost.image = oldImage
                    }
                    
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
        case view(View)
        case removePost(id: String)
        case fetchPosts
        case setPosts(PostResponse.MapPosts)
        case showFetchFailAlert
        case dismissProgress
        case setImage(postID: String, image: UIImage)
        case showFailedToGetPhotoLocationAlert
        case setLoadingIndicator(Bool)
        
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
                state.mapCameraCenterPosition = cameraPosition
                state.visibleBounds = bounds
                state.optimizeGeohashState(bounds: bounds)
                
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
                    await withTaskGroup(of: Void.self) { group in
                        for post in postsNeedingImage {
                            group.addTask {
                                do {
                                    let request = ImageClient.Request.Load(originUrl: post.imageURL, width: 240, height: 240)
                                    let image = try await imageClient.loadImage(request: request)
                                        
                                    let markerImage: UIImage? = await MainActor.run {
                                        let markerView = ImageMarkerView(image: Image(uiImage: image), title: post.title)
                                        return viewImageGenerator.generate(markerView)
                                    }
                                    
                                    guard let finalImage = markerImage else { return }
                                    await send(.setImage(postID: post.id, image: finalImage))
                                } catch {
                                    Logger.error("이미지 로드 실패")
                                }
                            }
                        }
                    }
                }
                .cancellable(id: EffectID.cancelImageLoad, cancelInFlight: true)
                
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
                
                return .run { [state] send in
                    await send(.setLoadingIndicator(true))
                    
                    let request = PostRequest.GetMapPost(
                        type: state.selectedFilter.rawValue,
                        latitude: state.mapCameraCenterPosition.lat,
                        longitude: state.mapCameraCenterPosition.lng,
                        precision: state.precision.rawValue,
                        hRadius: state.hRadius,
                        vRadius: state.vRadius
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
