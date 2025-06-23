//
//  PostClient.swift
//  Rim
//
//  Created by 노우영 on 6/18/25.
//

import Foundation
import Dependencies
import DependenciesMacros
import FirebaseFirestore
import FirebaseFunctions

@DependencyClient
struct PostClient {
    var post: (_ request: PostRequest) async throws -> Void
    var fetchNearPosts: () async throws -> [PostDTO]
    var fetchPostByID: (_ id: String) async throws -> PostDTO
    
    enum PostAPI: APITarget {
        case fetchNearPosts
        case fetchPostByID(id: String)
        
        var method: HTTPMethod {
            switch self {
            case .fetchNearPosts: .get
            case .fetchPostByID: .get
            }
        }
        
        var body: (any Encodable)? {
            nil
        }
        
        var headers: [String : String] {
            return [:]
        }
        
        var baseURLString: String { functionsURL }
        
        var path: String {
            switch self {
            case .fetchNearPosts: "/getPosts"
            case let .fetchPostByID(id): "/getPost/\(id)"
            }
        }
    }
}

extension PostClient: DependencyKey {
    static var liveValue: PostClient {
        PostClient { request in
            let firestore = Firestore.firestore(database: "mari-db")
            let data = try Firestore.Encoder().encode(request)
            
            let ref = try await firestore.collection("posts").addDocument(data: data)
        } fetchNearPosts: {
            try await Client.request(target: PostAPI.fetchNearPosts)
        } fetchPostByID: { id in
            try await Client.request(target: PostAPI.fetchPostByID(id: id))
        }
    }
}

extension DependencyValues {
    var postClient: PostClient {
        get { self[PostClient.self] }
        set { self[PostClient.self] = newValue }
    }
}



