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
        @Shared(.blockedUserIds) var blockedUserIds = Set()
        @Presents var alert: AlertState<Action.Alert>?
        @Presents var uploadPost: UploadPostNavigationStack.State?
        @Presents var camera: CameraFeature.State?
        
        // NaverMap에서 제공하는 줌 레벨의 최대값 22, 최솟값은 약 0.67
        // 값이 커질수록 확대됩니다 -page, 2025. 07. 04
        var zoomLevel: Double = 18.0
        
        var posts = IdentifiedArrayOf<PostSummaryState>()
        var retrievedGeoHashes: Set<String> = []
        var mapCameraCenterPosition = NMGLatLng(lat: 0, lng: 0)
        var photoLocation: NMGLatLng?
        
        var latestFilter = RimLabel.State(text: "최신순", textColor: .black)
        var isProgressPresented = false
        
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
        
        var cameraButton = RimImageView.State(image: .symbol(name: "camera", fgColor: .gray))
        var lastFetchPrecision: Int = 7
        
        var precision: Geohash.Precision {
            switch zoomLevel {
            case 0..<5:
                return .sixHundredThirtyKilometers
            case 5..<7:
                return .seventyEightKilometers
            case 7..<10:
                return .twentyKilometers
            case 10..<12:
                return .twentyFourHundredMeters
            case 12..<16:
                return .sixHundredTenMeters
            case 16..<19:
                return .seventySixMeters
            case 19..<20:
                return .nineteenMeters
            case 20...22:
                return .sixtyCentimeters
            default:
                return .seventyFourMillimeters
            }
        }
        
        var groupSize: Int {
            switch zoomLevel {
            case 17: 1
            default: 1
            }
        }
    }
    
    enum Filter: String {
        case latest
        case popular
    }
    
    enum EffectID {
        case fetchPosts
        case setPosts
    }
    
    enum Action: ViewAction {
        case alert(PresentationAction<Alert>)
        case uploadPost(PresentationAction<UploadPostNavigationStack.Action>)
        case camera(PresentationAction<CameraFeature.Action>)
        case view(UIAction)
        case removePost(id: String)
        case fetchPosts
        case setPosts(FetchNearPostsResponse)
        case showFetchFailAlert
        case dismissProgress
        case setImage(postID: String, image: UIImage)
        case cancelSetPosts
        case showFailedToGetPhotoLocationAlert
        
        enum UIAction: BindableAction {
            case cameraButtonTapped
            case binding(BindingAction<State>)
            case cameraDidMove(zoomLevel: Double, centerPosition: NMGLatLng)
        }
        
        enum Alert: Equatable {
            case openLocationSettings
        }
    }
    
    @Dependency(\.imageClient) var imageClient
    @Dependency(\.postClient) var postClient
    @Dependency(\.locationManager) var locationManager
    
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
                
            case let .view(.cameraDidMove(zoomLevel, cameraPosition)):
                state.zoomLevel = zoomLevel
                state.mapCameraCenterPosition = cameraPosition
                
                let centerGeoHash = Geohash.encode(latitude: cameraPosition.lat, longitude: cameraPosition.lng, precision: state.precision)
                guard !state.retrievedGeoHashes.contains(centerGeoHash) else { return .none }
                
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
                let oldIDs = Set(state.posts.map(\.id))
                let newIDs = Set(response.posts.map(\.id))
                let newPosts = response.posts.map { PostSummaryState(dto: $0) }
                
                let removedIDs = oldIDs.subtracting(newIDs)
                
                // 이미지 로드를 최소화하기 위해 added 상태 분리
                // 현재는 이미지 캐싱이 별도로 되어 있지 않습니다.
                // 이미지 캐싱 처리 후에는 remove/add 분리할 필요가 없습니다. -page 2025. 08. 06
                let addedIDs = newIDs.subtracting(oldIDs)
                let addedPosts = newPosts.filter { addedIDs.contains($0.id) }
                
                for removedPostId in removedIDs {
                    state.posts.remove(id: removedPostId)
                }
                
                for addedPost in addedPosts {
                    state.posts.append(addedPost)
                }
                
                state.retrievedGeoHashes = Set(response.geohashBlocks)
                
                return .run { send in
                    for addedPost in addedPosts {
                        do {
                            let imageSize = CGSize(width: 80, height: 80)
                            let image = try await imageClient.loadImage(url: addedPost.imageURL, size: imageSize)
                            await send(.setImage(postID: addedPost.id, image: image))
                        } catch {
                            // 실패 무시 or 처리
                        }
                    }
                }
                .cancellable(id: EffectID.setPosts)
                
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
                
                let request = FetchNearPostsRequest(
                    type: state.selectedFilter.rawValue,
                    latitude: state.mapCameraCenterPosition.lat,
                    longitude: state.mapCameraCenterPosition.lng,
                    precision: state.precision.rawValue,
                    groupSize: state.groupSize
                )
                
                return .run { send in
                    await send(.cancelSetPosts)
                    let response = try await postClient.fetchNearPosts(request).result
                    await send(.setPosts(response))
                    await send(.dismissProgress)
                } catch: { error, send in
                    Logger.debug(error.localizedDescription)
                    await send(.showFetchFailAlert)
                    await send(.dismissProgress)
                }
                    .debounce(id: EffectID.fetchPosts, for: .seconds(1), scheduler: RunLoop.main)
                
            case .cancelSetPosts:
                return .cancel(id: EffectID.setPosts)
                
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

