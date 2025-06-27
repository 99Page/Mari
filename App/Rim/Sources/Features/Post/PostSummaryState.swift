//
//  PostSummaryState.swift
//  Rim
//
//  Created by 노우영 on 6/23/25.
//

import CoreLocation
import Foundation

struct PostSummaryState: Equatable {
    let id: String
    let imageURL: String
    let title: String
    let location: CLLocation
    
    init(id: String, imageURL: String, title: String, coordinate: CLLocation) {
        self.id = id
        self.imageURL = imageURL
        self.title = title
        self.location = coordinate
    }
    
    init(dto: PostDTO) {
        self.id = dto.id
        self.imageURL = dto.imageUrl
        self.title = dto.title
        self.location = CLLocation(latitude: dto.location.latitude, longitude: dto.location.longitude)
    }
}
