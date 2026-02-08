//
//  PostSummaryState.swift
//  Rim
//
//  Created by 노우영 on 6/23/25.
//

import CoreLocation
import Foundation
import UIKit
import NMapsMap
import Geohash

struct MapPostState: Equatable, Identifiable, Hashable {
    let id: String
    let imageURL: String
    let title: String
    let location: CLLocation
    let creatorID: String
    var isPlaceholder: Bool = true
    let zIndex: Int
    let fetchedPrecision: Geohash.Precision
    
    var nmLocation: NMGLatLng {
        NMGLatLng(lat: location.coordinate.latitude, lng: location.coordinate.longitude)
    }
    
    init(
        id: String, imageURL: String, title: String,
        coordinate: CLLocation, creatorID: String, zIndex: Int,
        fetchedPrecision: Geohash.Precision
    ) {
        self.id = id
        self.imageURL = imageURL
        self.title = title
        self.location = coordinate
        self.creatorID = creatorID
        self.zIndex = zIndex
        self.fetchedPrecision = fetchedPrecision
    }
    
    init(dto: PostDetailDTO, fetchedPrecision: Geohash.Precision) {
        self.id = dto.id
        self.imageURL = dto.imageUrl
        self.title = dto.title
        self.creatorID = dto.creatorID
        self.location = CLLocation(latitude: dto.location.latitude, longitude: dto.location.longitude)
        self.fetchedPrecision = fetchedPrecision
        self.zIndex = Int(dto.createdAt.date.timeIntervalSince1970)
    }
    
    init(dto: MapPostDTO, fetchedPrecision: Geohash.Precision) {
        self.id = dto.id
        self.imageURL = dto.imageUrl
        self.title = dto.title
        self.creatorID = dto.creatorID
        self.location = CLLocation(latitude: dto.location.latitude, longitude: dto.location.longitude)
        self.zIndex =  Int(dto.createdAt.date.timeIntervalSince1970)
        self.fetchedPrecision = fetchedPrecision
    }
}
