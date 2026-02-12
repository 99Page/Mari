//
//  PostDetail.swift
//  Rim
//
//  Created by 노우영 on 2/10/26.
//

import Foundation
import CoreLocation
import Core

struct PostDetail: Identifiable, Equatable, Hashable, SectionProvidable {
    let id: String
    let imageURL: String
    let title: String
    let location: CLLocation
    let creatorID: String
    let description: String
    let section = 0
    
    init(id: String, imageURL: String, title: String, location: CLLocation, creatorID: String, description: String) {
        self.id = id
        self.imageURL = imageURL
        self.title = title
        self.location = location
        self.creatorID = creatorID
        self.description = description
    }
    
    init(dto: PostDetailDTO) {
        self.id = dto.id
        self.imageURL = dto.imageUrl
        self.title = dto.title
        self.location = CLLocation(latitude: dto.location.latitude, longitude: dto.location.longitude)
        self.creatorID = dto.creatorID
        self.description = dto.content
    }
    
    static func stub() -> Self {
        PostDetail(
            id: "",
            imageURL: "",
            title: "",
            location: CLLocation(latitude: 0, longitude: 0),
            creatorID: "",
            description: ""
        )
    }
}
