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
            let latitude: Double
            let longitude: Double
            let zoom: Int
        }
        
        // MARK: CreatePost
        struct Create: Encodable {
            let id: String
            let title: String
            let content: String
            let latitude: Double
            let longitude: Double
            let imageUrl: String
        }

    }
}
