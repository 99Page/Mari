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
    let thumbnailURL: String
    let title: String
    let location: CLLocation
    let creatorID: String
    let zIndex: Int
    let fetchedZoom: Int
    
    var nmLocation: NMGLatLng {
        NMGLatLng(lat: location.coordinate.latitude, lng: location.coordinate.longitude)
    }
    
    init(
        id: String, imageURL: String, title: String,
        coordinate: CLLocation, creatorID: String, zIndex: Int,
        fetchedZoom: Int, thumbnailURL: String
    ) {
        self.id = id
        self.imageURL = imageURL
        self.title = title
        self.location = coordinate
        self.creatorID = creatorID
        self.zIndex = zIndex
        self.fetchedZoom = fetchedZoom
        self.thumbnailURL = thumbnailURL
    }
    
    init(dto: PostDetailDTO, fetchedZoom: Int) {
        self.id = dto.id
        self.imageURL = dto.imageUrl
        self.title = dto.title
        self.creatorID = dto.creatorID
        self.location = CLLocation(latitude: dto.location.latitude, longitude: dto.location.longitude)
        self.fetchedZoom = fetchedZoom
        self.zIndex = Int(dto.createdAt.date.timeIntervalSince1970)
        
        if let thumbnail240Url = dto.thumbnail240Url {
            self.thumbnailURL = thumbnail240Url.isEmpty ? dto.imageUrl : thumbnail240Url
        } else {
            self.thumbnailURL = dto.imageUrl
        }
        
    }
    
    init(dto: MapPostDTO, fetchedZoom: Int) {
        self.id = dto.id
        self.imageURL = dto.imageUrl
        self.title = dto.title
        self.creatorID = dto.creatorID
        self.location = CLLocation(latitude: dto.location.latitude, longitude: dto.location.longitude)
        self.zIndex =  Int(dto.createdAt.date.timeIntervalSince1970)
        self.fetchedZoom = fetchedZoom
        self.thumbnailURL = dto.thumbnail240Url.isEmpty ? dto.imageUrl : dto.thumbnail240Url
    }
    
    static func stub() -> Self {
        return MapPostState(dto: MapPostDTO.stub(), fetchedZoom: 17)
    }
}
