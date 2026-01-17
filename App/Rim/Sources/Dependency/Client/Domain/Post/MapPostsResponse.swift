//
//  FetchNearPostsResponse.swift
//  Rim
//
//  Created by 노우영 on 7/4/25.
//

import Foundation

struct MapPostsResponse: Decodable, Stub {
    static func stub() -> MapPostsResponse {
        MapPostsResponse(posts: [.stub()], geohashBlocks: ["a", "b", "c"])
    }
    
    let posts: [MapPostDTO]
    let geohashBlocks: [String]
}
