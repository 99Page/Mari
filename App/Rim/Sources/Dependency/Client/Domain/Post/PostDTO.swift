//
//  PostDTO.swift
//  Rim
//
//  Created by 노우영 on 6/23/25.
//

import Foundation
import CoreLocation
import FirebaseCore

struct PostDetailDTO: Decodable, Stub {
    let id: String
    let title: String
    let content: String
    let imageUrl: String
    let thumbnail240Url: String?
    let thumbnail540url: String?
    let location: CoordinateDTO
    let creatorID: String
    let isMine: Bool
    let createdAt: TimestampDTO
    
    static func stub() -> Self {
        Self(id: UUID().uuidString, title: "title", content: "content", imageUrl: "https://picsum.photos/id/950/200/300", thumbnail240Url: "", thumbnail540url: "", location: .init(latitude: 0, longitude: 0), creatorID: "creator", isMine: true, createdAt: .init(seconds: 0, nanoseconds: 0))
    }
}

struct MapPostDTO: Decodable, Stub {
    let id: String
    let title: String
    let imageUrl: String
    let thumbnail240Url: String
    let thumbnail540Url: String
    let creatorID: String
    let location: CoordinateDTO
    let createdAt: TimestampDTO
    
    static func stub() -> Self {
        MapPostDTO(
            id: UUID().uuidString,
            title: "title",
            imageUrl: "https://picsum.photos/200/300",
            thumbnail240Url: "https://picsum.photos/540/675",
            thumbnail540Url: "https://picsum.photos/240/300",
            creatorID: "creatorID",
            location: .init(latitude: 0, longitude: 0),
            createdAt: .init(seconds: 0, nanoseconds: 0)
        )
    }
}
