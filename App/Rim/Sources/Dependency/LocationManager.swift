//
//  LocationManager.swift
//  Rim
//
//  Created by 노우영 on 7/30/25.
//

import Foundation
import CoreLocation
import Dependencies
import DependenciesMacros

@DependencyClient
struct LocationManager {
    var getCurrentLocation: () throws -> CLLocation
    
    enum LocationError: Error {
        case locationUnavailable
    }
}

extension LocationManager: DependencyKey {
    static var liveValue: LocationManager {
        LocationManager {
            let manager = CLLocationManager()
            guard let location = manager.location else { throw LocationError.locationUnavailable }
            return location
        }
    }
}

extension DependencyValues {
    var locationManager: LocationManager {
        get { self[LocationManager.self] }
        set { self[LocationManager.self] = newValue }
    }
}
