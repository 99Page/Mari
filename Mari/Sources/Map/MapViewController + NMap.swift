//
//  MapViewController + NMap.swift
//  Mari
//
//  Created by 노우영 on 5/26/25.
//

import Foundation
import NMapsMap

extension MapViewController: NMFMapViewCameraDelegate {
    func mapView(_ mapView: NMFMapView, cameraDidChangeByReason reason: Int, animated: Bool) {
        let zoomLevel = mapView.cameraPosition.zoom
        let projection = mapView.projection
        let frame = mapView.bounds

        let topLeft = projection.latlng(from: CGPoint(x: frame.minX, y: frame.minY))     // 좌측 상단
        let bottomLeft = projection.latlng(from: CGPoint(x: frame.minX, y: frame.maxY))  // 좌측 하단
        let topRight = projection.latlng(from: CGPoint(x: frame.maxX, y: frame.minY))    // 우측 상단
        let bottomRight = projection.latlng(from: CGPoint(x: frame.maxX, y: frame.maxY)) // 우측 하단
    }
}
