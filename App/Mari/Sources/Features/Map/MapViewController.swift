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

class MapViewController: UIViewController {
    
    private lazy var mapView: NMFMapView = {
        let mapView = NMFMapView(frame: view.bounds)
        return mapView
    }()
    
    private let postButton = UIButton(type: .custom)
    private let locationManager = CLLocationManager()

    override func viewDidLoad() {
        super.viewDidLoad()
        addOverlay()
    }
    
    private func setupView() {
        mapView.addCameraDelegate(delegate: self)
        
        scroll {
            onScroll {
                
            }
            
            horizontal {
                label {
                    text = "Hello"
                    textColor = .red
                }
            }
        }
        
        
        label {
            text = "Hello"
            textColor = .red
        }
        
        let label = UILabel()
        label.text = "Hello"
        label.textColor = .red
        
        view.addSubview(label)
        
        label.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        

//        ->
//        
//        let hstack = UIStackView()
//        view.addSubview(hstack)
//        hstack.axis = .horizontal
//        hstack.spacing = 5
//        
//        hstack.snp.makeConstraints { make in
//            make.edges.equalToSuperview()
//        }
//        
//        let label = UILabel()
//        hstack.addSubview(label)
//        
//        
//        let text = UILabel()
//        
//        observe {
//            
//        }
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
        debugPrint("show permision!")
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

        let marker = NMFMarker(position: coord)
        marker.iconImage = NMFOverlayImage(image: UIImage(resource: .mari))
        marker.mapView = mapView

        locationManager.stopUpdatingLocation()
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        addOverlay()
    }
}
