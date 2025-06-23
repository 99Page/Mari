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

@Reducer
struct TmpFeature {
    @ObservableState
    struct State {
    }
    
    enum Action { }
    
    @Dependency(\.postClient) var postClient
    
    var body: some ReducerOf<Self> {
        EmptyReducer()
    }
}

@ViewAction(for: MapFeature.self)
class MapViewController: UIViewController {
    
    @UIBindable var store: StoreOf<MapFeature>
    
    private lazy var mapView: NMFMapView = {
        let mapView = NMFMapView(frame: view.bounds)
        return mapView
    }()
    
    private var markers: [NMFMarker] = []
    private let postButton = UIButton(type: .custom)
    private let locationManager = CLLocationManager()
    
    init(store: StoreOf<MapFeature>) {
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
        addOverlay()
        updateView()
        
        send(.viewDidLoad)
        
        present(item: $store.scope(state: \.alert, action: \.alert)) { store in
            UIAlertController(store: store)
        }
        
        present(item: $store.scope(state: \.uploadPost, action: \.uploadPost)) { store in
            let viewController = UploadPostViewController(store: store)
            viewController.modalPresentationStyle = .fullScreen
            return viewController
        }
    }
    
    private func updateView() {
        observe { [weak self] in
            guard let self else { return }
            updateMarkers()
        }
    }
    
    private func updateMarkers() {
        removePresentedMarkers()
        addNewMarkers()
    }
    
    private func addNewMarkers() {
        for post in store.posts {
            guard let url = post.imageURL else { continue }
            
            let lat: Double = post.location.coordinate.latitude
            let lng: Double = post.location.coordinate.longitude
            
            let marker = NMFMarker(position: NMGLatLng(lat: lat, lng: lng))
            let imageLoader = NetworkImageLoader.init()
            
            marker.touchHandler = { [weak self] (o: NMFOverlay) -> Bool in

//                self?.traitCollection.push(state: MapNavigationStack.Path.State.postDetail(.init(postID: post.id)))
                return true
            }
            
            Task {
                do {
                    let image = try await imageLoader.loadImage(fromKey: url)
                    
                    marker.width = 80
                    marker.height = 80
                    marker.captionText = post.title.text
                    marker.iconImage = NMFOverlayImage(image: image)
                    marker.mapView = mapView
                    markers.append(marker)
                } catch {
                    debugPrint("load fail: \(error)")
                }
            }
        }
    }
    
    private func removePresentedMarkers() {
        for marker in markers {
            marker.mapView = nil
        }
        
        markers.removeAll()
    }
    
    private func makeConstraint() {
        view.addSubview(mapView)
        view.addSubview(postButton)
        
        mapView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        postButton.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-16)
            make.bottom.equalToSuperview().offset(-16)
            make.width.height.equalTo(50)
        }
    }
    
    private func setupView() {
        mapView.addCameraDelegate(delegate: self)
        
        // 추후 줌 기능을 추가합니다. 현재는 API 호출의 편의성을 위해 일시적으로
        // 줌 기능을 막습니다 -page 2025. 06. 23
        mapView.isZoomGestureEnabled = false
        
        postButton.setImage(UIImage(systemName: "camera"), for: .normal)
        
        postButton.addAction(UIAction(handler: { [weak self] _ in
            self?.presentCamera()
        }), for: .touchUpInside)
    }
    
    
    private func addOverlay() {
        locationManager.delegate = self
        
        switch locationManager.authorizationStatus {
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
            debugPrint("not detemined")
        case .authorizedWhenInUse, .authorizedAlways:
            debugPrint("start updating")
            locationManager.startUpdatingLocation()
        case .restricted, .denied:
            showLocationPermissionAlert()
        @unknown default:
            break
        }
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

        mapView.moveCamera(NMFCameraUpdate(scrollTo: coord))

        locationManager.stopUpdatingLocation()
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        addOverlay()
    }
}

private extension MapViewController {
    func presentCamera() {
        guard UIImagePickerController.isSourceTypeAvailable(.camera) else {
            print("Camera not available")
            return
        }

        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = self
        picker.allowsEditing = false
        present(picker, animated: true)

    }
}

extension MapViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        
        debugPrint("event called")
        
        if let image = info[.originalImage] as? UIImage {
            send(.cameraButtonTapped(image))
        }
    }

    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {

    }
}
