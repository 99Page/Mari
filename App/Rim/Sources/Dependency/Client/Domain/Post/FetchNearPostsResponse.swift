//
//  FetchNearPostsResponse.swift
//  Rim
//
//  Created by 노우영 on 9/16/25.
//

import Foundation

struct FetchNearPostsResponse: Decodable, Stub {
    let posts: [PostDetailDTO]
    
    static func stub() -> FetchNearPostsResponse {
        FetchNearPostsResponse(posts: [.stub()])
    }
}
