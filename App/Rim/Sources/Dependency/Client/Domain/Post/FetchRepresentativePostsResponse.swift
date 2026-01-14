//
//  FetchNearPostsResponse.swift
//  Rim
//
//  Created by 노우영 on 7/4/25.
//

import Foundation

struct FetchRepresentativePostsResponse: Decodable, Stub {
    static func stub() -> FetchRepresentativePostsResponse {
        FetchRepresentativePostsResponse(posts: [.stub()], geohashBlocks: ["a", "b", "c"])
    }
    
    let posts: [PostSummaryDTO]
    let geohashBlocks: [String]
}
