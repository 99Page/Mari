//
//  FetchNearPostsResponse.swift
//  Rim
//
//  Created by 노우영 on 7/4/25.
//

import Foundation

struct FetchNearPostsResponse: Decodable {
    let posts: [PostDTO]
    let geohashBlocks: [String]
}
