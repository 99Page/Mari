//
//  MapViewController.swift
//  Mari
//
//  Created by 노우영 on 5/26/25.
//

import Foundation
import UIKit
import NMapsMap
import CoreLocation
import Core
import ComposableArchitecture
import SwiftUI
import Kingfisher

@ViewAction(for: MapFeature.self)
class UIMapViewController: UIViewController, NMFMapViewCameraDelegate {
    
    @Dependency(\.viewImageGenerator) var viewImageGenerator
    
    @UIBindable var store: StoreOf<MapFeature>
    
    private let markerWidth: CGFloat = 98
    private let markerHeight: CGFloat = 86
    
    private lazy var mapView: NMFMapView = {
        let mapView = NMFMapView(frame: view.bounds)
        return mapView
    }()
    
    private var activeMarkers: [String: NMFMarker] = [:]
    
    private let locationManager = CLLocationManager()
    private var isUserLocationInitialized = false
    
    private let progressView = UIActivityIndicatorView(style: .medium)
    
    private let cameraButton = UIButton()
    
    private let currentLocationButton = UIButton()
    
    private var selectedMarker: NMFMarker?
    
    private lazy var cachedLockedIcon: UIImage = {
        let size = CGSize(width: markerWidth, height: markerHeight)
        return resizedImage(UIImage(systemName: "lock.circle")!, size: size)
    }()
    
    @MainActor
    private var placeholderIcon: UIImage {
        let markerView = ImageMarkerView(
            image: Image(.placeholder),
            title: "",
            contentMode: .fit
        )
        
        return viewImageGenerator.generate(markerView) ?? UIImage()
    }
    
    init(store: StoreOf<MapFeature>) {
        @UIBindable var binding = store
        self.store = store
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        makeConstraint()
        setupView()
        updateView()
        
        present(item: $store.scope(state: \.alert, action: \.alert)) { store in
            UIAlertController(store: store)
        }
        
        present(item: $store.scope(state: \.uploadPost, action: \.uploadPost)) { store in
            let viewController = UploadPostStackController(store: store)
            viewController.modalPresentationStyle = .fullScreen
            return viewController
        }
        
        present(item: $store.scope(state: \.camera, action: \.camera)) { store in
            CameraViewController(store: store)
        }
        
        present(item: $store.scope(state: \.logIn, action: \.logIn)) { store in
            let viewController = UILogInViewController(store: store)
            
            if let sheet = viewController.sheetPresentationController {
                sheet.detents = [
                    .custom { context in
                        return viewController.view.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize).height
                    }
                ]
                sheet.prefersGrabberVisible = true
            }
            
            return viewController
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        currentLocationButton.layer.cornerRadius = currentLocationButton.frame.height / 2
        cameraButton.layer.cornerRadius = cameraButton.frame.height / 2
    }
    
    private func updateView() {
        observe { [weak self] in
            guard let self else { return }
            updateMarkers()
        }
        
        observe { [weak self] in
            guard let self else { return }
            updateProgressView()
        }
    }
    
    private func updateProgressView() {
        store.isProgressPresented ? progressView.startAnimating() : progressView.stopAnimating()
    }
    
    private func updateMarkers() {
        removeMarkers()
        syncMarkers()
    }
    
    private func syncMarkers() {
        for post in store.posts {
            if let existingMarker = activeMarkers[post.id] {
                let cachedUrl = existingMarker.userInfo["url"] as? String
                if cachedUrl != post.imageURL {
                    updateMarkerImage(for: post, on: existingMarker)
                }
            } else {
                let marker = makeNewMarker(post)
                marker.mapView = mapView
                activeMarkers[post.id] = marker
            }
        }
    }
    
    private func makeNewMarker(_ post: MapPostState) -> NMFMarker {
        let iconImage: UIImage
        let markerSize = CGSize(width: markerWidth, height: markerHeight)
        
        if store.blockedUserIds.contains(post.creatorID) {
            iconImage = cachedLockedIcon
        } else {
            iconImage = placeholderIcon
        }
        
        
        let lat: Double = post.location.coordinate.latitude
        let lng: Double = post.location.coordinate.longitude
        let marker = NMFMarker(position: NMGLatLng(lat: lat, lng: lng))
        marker.width = markerSize.width
        marker.height = markerSize.height
        marker.isHideCollidedMarkers = true
        marker.zIndex = post.zIndex
        marker.anchor = CGPoint(x: 0.5, y: 1)
        marker.iconImage = NMFOverlayImage(image: iconImage)
        marker.userInfo = ["url": post.imageURL]
        
        marker.touchHandler = { [weak self] _ in
            guard let self else { return false } // 지도 탭 이벤트 허용
            self.selectedMarker = marker
            traitCollection.push(state: MapNavigationStack.Path.State.postList(.init(imageURL: post.imageURL)))
            return true // 지도 탭 무시
        }
        
        updateMarkerImage(for: post, on: marker)
        return marker
    }
    
    private func updateMarkerImage(for post: MapPostState, on marker: NMFMarker) {
        if store.blockedUserIds.contains(post.creatorID) {
            marker.iconImage = NMFOverlayImage(image: cachedLockedIcon)
        } else {
            Task {
                let loadedImage = await loadMarkerImage(for: post)
                await MainActor.run {
                    marker.iconImage = NMFOverlayImage(image: loadedImage)
                }
            }
        }
    }
    
    func loadMarkerImage(for post: MapPostState) async -> UIImage {
        
        let rawUrlString = post.thumbnailURL
        let markerCacheKey = rawUrlString.isEmpty ? "empty_post_marker" : rawUrlString + "_processed_marker"
        
        let cache = KingfisherManager.shared.cache
        
        if let result = try? await cache.retrieveImage(forKey: markerCacheKey),
           let cachedMarker = result.image {
            return cachedMarker
        }
        
        var sourceImage: UIImage?
        var contentMode: SwiftUI.ContentMode
        
        if let url = URL(string: rawUrlString) {
            do {
                let result = try await KingfisherManager.shared.retrieveImage(with: url)
                sourceImage = result.image
                contentMode = .fill // 📸 사진은 꽉 채우기
            } catch {
                sourceImage = nil // 실패 시 아래에서 플레이스홀더 처리
                contentMode = .fit
            }
        } else {
            sourceImage = nil
            contentMode = .fit
        }
        
        let finalImageToRender = sourceImage ?? UIImage(resource: .placeholder)
        if sourceImage == nil { contentMode = .fit }
        
        let generatedMarker = await MainActor.run {
            let markerView = ImageMarkerView(
                image: Image(uiImage: finalImageToRender),
                title: post.title,
                contentMode: contentMode
            )
            return viewImageGenerator.generate(markerView)
        } ?? UIImage()
        
        try? await cache.store(generatedMarker, forKey: markerCacheKey, toDisk: false)
        return generatedMarker
    }
    
    private func removeMarkers() {
        let idsToRemove = activeMarkers.keys.filter { store.posts[id: $0] == nil }
        
        for id in idsToRemove {
            activeMarkers[id]?.mapView = nil
            activeMarkers.removeValue(forKey: id)
        }
    }
    
    private func makeConstraint() {
        view.addSubview(mapView)
        view.addSubview(cameraButton)
        view.addSubview(currentLocationButton)
        view.addSubview(progressView)
        
        mapView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        currentLocationButton.snp.makeConstraints { make in
            make.bottom.equalTo(view.safeAreaLayoutGuide).inset(16)
            make.trailing.equalToSuperview().inset(16)
            make.width.height.equalTo(40)
        }
        
        cameraButton.snp.makeConstraints { make in
            make.centerY.equalTo(currentLocationButton)
            make.trailing.equalTo(currentLocationButton.snp.leading).offset(-10)
            make.width.height.equalTo(40)
        }
        
        progressView.snp.makeConstraints { make in
            make.height.width.equalTo(20)
            make.bottom.equalToSuperview().inset(40)
            make.leading.equalToSuperview().inset(16)
        }
    }
    
    private func setupView() {
        addOverlay()
        
        mapView.addCameraDelegate(delegate: self)
        mapView.zoomLevel = 17
        mapView.locationOverlay.hidden = false
        
        progressView.startAnimating()
        progressView.color = .gray
        
        setupCameraButton()
        setupLocationButton()
    }
    
    private func setupLocationButton() {
        applySharedButtonStyle(to: currentLocationButton, iconName: "location")
        currentLocationButton.addTarget(self, action: #selector(didTapCurrentLocationButton), for: .touchUpInside)
    }
    
    private func applySharedButtonStyle(to button: UIButton, iconName: String) {
        button.backgroundColor = .white
        button.layer.borderWidth = 1.5
        button.layer.borderColor = UIColor.systemBlue.cgColor
        
        button.layer.shadowColor = UIColor.black.cgColor
        button.layer.shadowOpacity = 0.15
        button.layer.shadowOffset = CGSize(width: 0, height: 2)
        button.layer.shadowRadius = 4
        
        let config = UIImage.SymbolConfiguration(pointSize: 18, weight: .semibold)
        button.setImage(UIImage(systemName: iconName, withConfiguration: config), for: .normal)
        button.tintColor = .systemBlue
    }
    
    
    
    @objc private func didTapCurrentLocationButton() {
        guard let location = locationManager.location else { return }
        let coord = NMGLatLng(lat: location.coordinate.latitude, lng: location.coordinate.longitude)
        let cameraUpdate = NMFCameraUpdate(scrollTo: coord, zoomTo: mapView.zoomLevel)
        cameraUpdate.animation = .easeIn
        mapView.moveCamera(cameraUpdate)
    }
    
    private func setupCameraButton() {
        applySharedButtonStyle(to: cameraButton, iconName: "camera")
        
        // 액션 추가
        cameraButton.addAction(UIAction { [weak self] _ in
            self?.send(.cameraButtonTapped)
        }, for: .touchUpInside)
    }
    
    private func addOverlay() {
        locationManager.delegate = self
        
        switch locationManager.authorizationStatus {
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        case .authorizedWhenInUse, .authorizedAlways:
            locationManager.startUpdatingLocation()
        case .restricted, .denied:
            showLocationPermissionAlert()
        @unknown default:
            break
        }
    }
    
    // 카메라 이동이 모두 끝났을 때 호출됩니다. -page 2025. 07. 01
    func mapViewCameraIdle(_ mapView: NMFMapView) {
        let centerPosition = mapView.cameraPosition
        send(.cameraDidMove(centerPosition: centerPosition.target,
                            bounds: mapView.coveringBounds,
                            zoom: mapView.zoomLevel))
    }
    
    private func showLocationPermissionAlert() {
        let alert = UIAlertController(
            title: "위치 권한 필요",
            message: "현재 위치를 사용하려면 설정에서 위치 권한을 허용해주세요.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "설정으로 이동", style: .default) { _ in
            if let appSettings = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(appSettings)
            }
        })
        alert.addAction(UIAlertAction(title: "취소", style: .cancel))
        present(alert, animated: true)
    }
}

extension UIMapViewController: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        
        let coord = NMGLatLng(lat: location.coordinate.latitude,
                              lng: location.coordinate.longitude)
        
        if !isUserLocationInitialized {
            mapView.moveCamera(NMFCameraUpdate(scrollTo: coord))
            isUserLocationInitialized = true
        }
        
        mapView.locationOverlay.location = coord
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        addOverlay()
    }
}

extension UIMapViewController: ExpandTransitionSourceDelegate {
    func transitionSourceRect() -> CGRect? {
        guard let selectedMarker = self.selectedMarker else { return nil }
        
        let point = mapView.projection.point(from: selectedMarker.position)
        
        let width = ImageMarkerView.Layout.imageSize.width
        let height = ImageMarkerView.Layout.imageSize.height

        let imageTopOffset = ImageMarkerView.Layout.totalHeightOffset - ImageMarkerView.Layout.containerPadding
        
        return CGRect(
            x: point.x - (width / 2),
            y: point.y - imageTopOffset,
            width: width,
            height: height
        )
    }
    
    func transitionInitialCornerRadius() -> CGFloat {
        ImageMarkerView.Layout.imageCornerRadius
    }
}

extension UIMapViewController: TransitionHandler {
    func transitionAnimator(
        operation: UINavigationController.Operation,
        from fromVC: UIViewController,
        to toVC: UIViewController
    ) -> UIViewControllerAnimatedTransitioning? {
        
        
        if operation == .push && toVC is PostListViewController {
            return ExpandAnimator(isPresenting: true)
        }
        
        if operation == .pop && fromVC is PostListViewController {
            return ExpandAnimator(isPresenting: false)
        }
        
        return nil
    }
}

private extension UIMapViewController {
    func resizedImage(_ image: UIImage, size: CGSize) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: size))
        }
    }
}

#Preview {
    let store = Store(initialState: MapFeature.State()) {
        MapFeature()
    }
    
    ViewControllerPreview {
        UIMapViewController(store: store)
    }
    .ignoresSafeArea()
}
