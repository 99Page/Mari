//
//  PostClient + Request.swift
//  Rim
//
//  Created by 노우영 on 1/17/26.
//

import Foundation

typealias PostRequest = PostClient.Request

extension PostClient {
    enum Request {
        // MARK: MapPost
        struct GetMapPost: Encodable {
            let type: String
            let latitude: Double
            let longitude: Double
            let precision: Int
            let groupSize: Int
        }
        
        // MARK: CreatePost
        struct Create: Encodable {
            let title: String
            let content: String
            let latitude: Double
            let longitude: Double
            let creatorID: String
            let imageUrl: String
        }

    }
}
