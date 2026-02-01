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

@ViewAction(for: MapFeature.self)
class MapViewController: UIViewController, NMFMapViewCameraDelegate {
    @UIBindable var store: StoreOf<MapFeature>
    
    private lazy var mapView: NMFMapView = {
        let mapView = NMFMapView(frame: view.bounds)
        return mapView
    }()
    
    private var activeMarkers: [String: NMFMarker] = [:]
    
    private let locationManager = CLLocationManager()
    private var isUserLocationInitialzed = false
    
    private let progressView = UIActivityIndicatorView(style: .medium)
    
    private let cameraButton = UIButton()
    
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
    }
    
    private func updateView() {
        observe { [weak self] in
            guard let self else { return }
            updateMarkers()
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
            let iconImage: UIImage
            let markerSize = CGSize(width: 94, height: 86)
            
            if store.blockedUserIds.contains(post.creatorID) {
                iconImage = resizedImage(UIImage(systemName: "lock.circle")!, size: markerSize)
            } else {
                iconImage = post.image ?? UIImage(resource: .placeholder)
            }
            
            if let existingMarker = activeMarkers[post.id] {
                existingMarker.iconImage = NMFOverlayImage(image: iconImage)
            } else {
                let marker = makeNewMarker(post)
                marker.mapView = mapView
                activeMarkers[post.id] = marker
            }
        }
    }
    
    private func makeNewMarker(_ post: MapPostState) -> NMFMarker {
        let iconImage: UIImage
        let markerSize = CGSize(width: 94, height: 86)
        
        if store.blockedUserIds.contains(post.creatorID) {
            iconImage = resizedImage(UIImage(systemName: "lock.circle")!, size: markerSize)
        } else {
            iconImage = post.image ?? UIImage(resource: .placeholder)
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
        
        return marker
    }
    
    private func removeMarkers() {
        for (id, marker) in activeMarkers {
            guard store.posts[id: id] == nil else { continue }
            marker.mapView = nil
            activeMarkers.removeValue(forKey: id)
        }
    }
    
    private func makeConstraint() {
        
        view.addSubview(mapView)
        view.addSubview(cameraButton)
        view.addSubview(progressView)
        
        mapView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        cameraButton.snp.makeConstraints { make in
            make.bottom.equalToSuperview().inset(16)
            make.trailing.equalToSuperview().inset(16)
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
    }
    
    private func setupCameraButton() {
        let imageSize = CGFloat(20)
        let inset = imageSize / 2
        let symbolConfig = UIImage.SymbolConfiguration(pointSize: imageSize, weight: .bold, scale: .medium)
        let image = UIImage(systemName: "camera.fill", withConfiguration: symbolConfig)
        
        var config = UIButton.Configuration.filled()
        config.image = image
        config.baseBackgroundColor = .systemBlue
        config.baseForegroundColor = .white
        config.cornerStyle = .capsule
        config.contentInsets = NSDirectionalEdgeInsets(top: inset, leading: inset, bottom: inset, trailing: inset)
        
        cameraButton.configuration = config
        cameraButton.layer.shadowColor = UIColor.black.cgColor
        cameraButton.layer.shadowOpacity = 0.3
        cameraButton.layer.shadowOffset = CGSize(width: 0, height: 4)
        cameraButton.layer.shadowRadius = 4
        cameraButton.translatesAutoresizingMaskIntoConstraints = false
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
        let zoomLevel = mapView.zoomLevel
        let centerPosition = mapView.cameraPosition
        send(.cameraDidMove(centerPosition: centerPosition.target, bounds: mapView.coveringBounds))
        Logger.debug("\(mapView.zoomLevel)")
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

extension MapViewController: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        
        let coord = NMGLatLng(lat: location.coordinate.latitude,
                              lng: location.coordinate.longitude)
        
        if !isUserLocationInitialzed {
            mapView.moveCamera(NMFCameraUpdate(scrollTo: coord))
            isUserLocationInitialzed = true
        }
        
        mapView.locationOverlay.location = coord
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        addOverlay()
    }
}

extension MapViewController: UINavigationControllerDelegate {
    
}

private extension MapViewController {
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
        MapViewController(store: store)
    }
    .ignoresSafeArea()
}
