//
//  PostDTO.swift
//  Rim
//
//  Created by 노우영 on 6/23/25.
//

import Foundation
import CoreLocation

struct PostDetailDTO: Decodable, Stub {
    let id: String
    let title: String
    let content: String
    let imageUrl: String
    let location: CoordinateDTO
    let isMine: Bool
    
    static func stub() -> Self {
        Self(id: UUID().uuidString, title: "title", content: "content", imageUrl: "imageURL", location: .init(latitude: 0, longitude: 0), isMine: true)
    }
}

struct PostSummaryDTO: Decodable, Stub {
    let id: String
    let title: String
    let imageUrl: String
    let location: CoordinateDTO
    
    static func stub() -> Self {
        PostSummaryDTO(
            id: UUID().uuidString,
            title: "title",
            imageUrl: "https://picsum.photos/200/300",
            location: .init(latitude: 0, longitude: 0)
        )
    }
}

struct CoordinateDTO: Decodable {
    let latitude: Double
    let longitude: Double

    private enum CodingKeys: String, CodingKey {
        case latitude = "_latitude"
        case longitude = "_longitude"
    }
}
