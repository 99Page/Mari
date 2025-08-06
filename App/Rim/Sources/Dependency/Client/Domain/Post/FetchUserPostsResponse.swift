//
//  FetchUserPostsResponse.swift
//  Rim
//
//  Created by 노우영 on 7/15/25.
//

import Foundation

struct FetchUserPostsResponse: Decodable, Stub {
    let posts: [PostSummaryDTO]
    let nextCursor: Date? // 더 가져올게 없는 경우 nil
    
    static func stub() -> FetchUserPostsResponse {
        FetchUserPostsResponse(posts: .stub(), nextCursor: .now)
    }
}
