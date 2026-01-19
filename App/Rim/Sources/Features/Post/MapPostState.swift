//
//  PostSummaryState.swift
//  Rim
//
//  Created by 노우영 on 6/23/25.
//

import CoreLocation
import Foundation
import UIKit

struct MapPostState: Equatable, Identifiable, Hashable {
    let id: String
    let imageURL: String
    let title: String
    let location: CLLocation
    let creatorID: String
    var image: UIImage?
    let zIndex: Int
    
    init(id: String, imageURL: String, title: String, coordinate: CLLocation, creatorID: String, zIndex: Int) {
        self.id = id
        self.imageURL = imageURL
        self.title = title
        self.location = coordinate
        self.creatorID = creatorID
        self.zIndex = zIndex
    }
    
    init(dto: PostDetailDTO) {
        self.id = dto.id
        self.imageURL = dto.imageUrl
        self.title = dto.title
        self.creatorID = dto.creatorID
        self.location = CLLocation(latitude: dto.location.latitude, longitude: dto.location.longitude)
        self.zIndex = Int(dto.createdAt.date.timeIntervalSince1970)
    }
    
    init(dto: MapPostDTO) {
        self.id = dto.id
        self.imageURL = dto.imageUrl
        self.title = dto.title
        self.creatorID = dto.creatorID
        self.location = CLLocation(latitude: dto.location.latitude, longitude: dto.location.longitude)
        self.zIndex =  Int(dto.createdAt.date.timeIntervalSince1970)
    }
}
