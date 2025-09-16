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
    let location: CoordinateDTO
    let creatorID: String
    let isMine: Bool
    let createdAt: TimestampDTO
    
    static func stub() -> Self {
        Self(id: UUID().uuidString, title: "title", content: "content", imageUrl: "https://picsum.photos/id/950/200/300", location: .init(latitude: 0, longitude: 0), creatorID: "creator", isMine: true, createdAt: .init(seconds: 0, nanoseconds: 0))
    }
}

struct PostSummaryDTO: Decodable, Stub {
    let id: String
    let title: String
    let imageUrl: String
    let creatorID: String
    let location: CoordinateDTO
    
    static func stub() -> Self {
        PostSummaryDTO(
            id: UUID().uuidString,
            title: "title",
            imageUrl: "https://picsum.photos/200/300",
            creatorID: "creatorID",
            location: .init(latitude: 0, longitude: 0)
        )
    }
}
