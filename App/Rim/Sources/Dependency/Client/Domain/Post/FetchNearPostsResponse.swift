//
//  FetchNearPostsResponse.swift
//  Rim
//
//  Created by 노우영 on 7/4/25.
//

import Foundation

struct FetchNearPostsResponse: Decodable, Stub {
    static func stub() -> FetchNearPostsResponse {
        FetchNearPostsResponse(posts: [.stub()], geohashBlocks: ["a", "b", "c"])
    }
    
    let posts: [PostSummaryDTO]
    let geohashBlocks: [String]
}
