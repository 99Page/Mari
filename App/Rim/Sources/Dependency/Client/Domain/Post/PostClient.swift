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
    var createPost: (_ request: CreatePostRequest) async throws -> PostDTO
    var fetchNearPosts: (_ request: FetchNearPostsRequest) async throws -> FetchNearPostsResponse
    var fetchPostByID: (_ id: String) async throws -> PostDTO
    
    enum PostAPI: APITarget {
        case createPost(request: CreatePostRequest)
        case fetchNearPosts(request: FetchNearPostsRequest)
        case fetchPostByID(id: String)
        
        var method: HTTPMethod {
            switch self {
            case .fetchNearPosts: .get
            case .fetchPostByID: .get
            case .createPost: .post
            }
        }
        
        var body: (any Encodable)? {
            switch self {
            case .createPost(let request): request
            case .fetchNearPosts: nil
            case .fetchPostByID: nil
            }
        }
        
        var headers: [String : String] {
            var headers: [String: String] = [:]
            
            @Dependency(\.keychain) var keychain
            
            switch self {
            case .createPost:
                let idToken = try? keychain.load(service: .firebase, account: .idToken)
                headers["Authorization"] = "Bearer \(idToken ?? "")"
            case .fetchNearPosts:
                break
            case .fetchPostByID:
                break
            }
            return headers
        }
        
        var baseURLString: String { functionsURL }
        
        var path: String {
            switch self {
            case .createPost: "/createPost"
            case let .fetchNearPosts(request):
                "/getPosts/?latitude=\(request.latitude)&longitude=\(request.longitude)&precision=\(request.precision)&type=\(request.type)"
            case let .fetchPostByID(id): "/getPostById?id=\(id)"
            }
        }
    }
}

extension PostClient: DependencyKey {
    static var liveValue: PostClient {
        PostClient { request in
            try await Client.request(target: PostAPI.createPost(request: request))
        } fetchNearPosts: { request in
            try await Client.request(target: PostAPI.fetchNearPosts(request: request))
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



