//
//  PostDTO.swift
//  Rim
//
//  Created by 노우영 on 6/23/25.
//

import Foundation
import CoreLocation

struct PostDTO: Decodable {
    let id: String
    let title: String
    let content: String
    let imageUrl: String
    let location: Coordinate
    
    static func stub() -> PostDTO {
        PostDTO(id: "id", title: "title", content: "content", imageUrl: "imageURL", location: .init(latitude: 0, longitude: 0))
    }

    struct Coordinate: Decodable {
        let latitude: Double
        let longitude: Double

        private enum CodingKeys: String, CodingKey {
            case latitude = "_latitude"
            case longitude = "_longitude"
        }
    }
}
