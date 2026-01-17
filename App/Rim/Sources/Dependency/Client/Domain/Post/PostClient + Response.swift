//
//  PostClient + Response.swift
//  Rim
//
//  Created by 노우영 on 1/17/26.
//

import Foundation

typealias PostResponse = PostClient.Response

extension PostClient {
    enum Response {
        struct MapPosts: Decodable, Stub {
            static func stub() -> MapPosts {
                MapPosts(posts: [.stub()], geohashBlocks: ["a", "b", "c"])
            }
            
            let posts: [MapPostDTO]
            let geohashBlocks: [String]
        }

    }
}
