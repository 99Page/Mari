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
    
    private var markers: [NMFMarker] = []
    private let locationManager = CLLocationManager()
    private var isUserLocationInitialzed = false
    
    private let latestBackgroundView: RimView
    private let latestLabel: RimLabel
    
    private let popularBackgroundView: RimView
    private let popularLabel: RimLabel
    
    private let progressView = UIActivityIndicatorView(style: .medium)
    
    private let cameraButton: RimImageView
    private let cameraBackgroundView: RimView
    
    init(store: StoreOf<MapFeature>) {
        @UIBindable var binding = store
        self.store = store
        
        self.latestLabel = RimLabel(state: $binding.latestFilter)
        self.popularLabel = RimLabel(state: $binding.popularFilter)
        self.latestBackgroundView = RimView(state: $binding.latestBackground)
        self.popularBackgroundView = RimView(state: $binding.popularBackground)
        
        self.cameraButton = RimImageView(state: $binding.cameraButton)
        self.cameraBackgroundView = RimView(state: .constant(.init(borderColor: .gray, borderWidth: 1, cornerRadius: 20, backgroundColor: .systemBackground, shadowColor: .gray, shadowOpacity: 0.8, shadowOffset: CGSize(width: 0, height: 0.5), shadowRadius: 1)))
        
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
        removePresentedMarkers()
        addNewMarkers()
    }
    
    private func addNewMarkers() {
        for post in store.posts {
            let lat: Double = post.location.coordinate.latitude
            let lng: Double = post.location.coordinate.longitude            
            let marker = NMFMarker(position: NMGLatLng(lat: lat, lng: lng))

            marker.touchHandler = { [weak self] (o: NMFOverlay) -> Bool in
                self?.traitCollection.push(state: MapNavigationStack.Path.State.postDetail(.init(postID: post.id)))
                return true
            }
            
            marker.captionText = post.title
            marker.width = 80
            marker.height = 80
            
            let iconImage = post.image ?? UIImage(resource: .placeholder)
            marker.iconImage = NMFOverlayImage(image: iconImage)
            marker.mapView = mapView
            
            markers.append(marker)
        }
    }
    
    private func removePresentedMarkers() {
        for marker in markers {
            marker.mapView = nil
        }
        
        markers.removeAll()
    }
    
    private func makeConstraint() {
        let filterContainerView = UIView()
        
        view.addSubview(mapView)
        view.addSubview(filterContainerView)
        view.addSubview(cameraBackgroundView)
        
        filterContainerView.addSubview(latestBackgroundView)
        filterContainerView.addSubview(popularBackgroundView)
        filterContainerView.addSubview(progressView)
        
        cameraButton.background(cameraBackgroundView, insets: UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8))
        
        let filterBgInsets = UIEdgeInsets(top: 5, left: 8, bottom: 5, right: 8)
        
        mapView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        cameraButton.snpTarget.makeConstraints { make in
            make.bottom.equalTo(filterContainerView.snp.top).offset(-8)
            make.trailing.equalTo(filterContainerView)
            make.width.height.equalTo(40)
        }
        
        filterContainerView.snp.makeConstraints { make in
            make.bottom.equalToSuperview().offset(-16)
            make.trailing.equalToSuperview().offset(-16)
        }
        
        progressView.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.height.width.equalTo(20)
            make.leading.equalToSuperview()
        }
        
        latestLabel.background(latestBackgroundView, insets: filterBgInsets)
        latestLabel.snpTarget.makeConstraints { make in
            make.top.bottom.equalToSuperview()
            make.leading.equalTo(progressView.snp.trailing).offset(6)
        }
        
        popularLabel.background(popularBackgroundView, insets: filterBgInsets)
        popularLabel.snpTarget.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.leading.equalTo(latestLabel.snpTarget.trailing).offset(6)
            make.trailing.equalToSuperview()
        }
    }
    
    private func setupView() {
        addOverlay()
        
        mapView.addCameraDelegate(delegate: self)
        mapView.zoomLevel = 17
        mapView.locationOverlay.hidden = false
        
        navigationController?.setNavigationBarHidden(true, animated: false)
        
        latestBackgroundView.addAction(.touchUpInside({ [weak self] in
            self?.store.selectedFilter = .latest
        }))
        
        popularBackgroundView.addAction(.touchUpInside({ [weak self] in
            self?.store.selectedFilter = .popular
        }))
        
        progressView.startAnimating()
        progressView.color = .gray
        
        cameraBackgroundView.addAction(.touchUpInside({ [weak self] in
            self?.presentCamera()
        }))
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
        send(.cameraDidMove(zoomLevel: zoomLevel, centerPosition: centerPosition.target))
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

private extension MapViewController {
    func presentCamera() {
        store.camera = CameraFeature.State()
//        guard UIImagePickerController.isSourceTypeAvailable(.camera) else {
//            print("Camera not available")
//            return
//        }
//        
//        let picker = UIImagePickerController()
//        picker.sourceType = .camera
//        picker.delegate = self
//        picker.allowsEditing = false
//        present(picker, animated: true)
    }
}

extension MapViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let image = info[.originalImage] as? UIImage {
            send(.usePhotoButtonTapped(image))
        }
    }
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
