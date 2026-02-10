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
                MapPosts(posts: [.stub()], zoomLevel: 17, appliedPrecision: 18, postCount: 1)
            }
            
            let posts: [MapPostDTO]
            let zoomLevel: Int
            let appliedPrecision: Int
            let postCount: Int
        }

        
        struct Delete: Decodable, Stub {
            let id: String
            
            static func stub() -> Self {
                .init(id: "1")
            }
        }

    }
}
