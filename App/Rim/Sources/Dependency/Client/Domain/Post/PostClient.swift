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
    var incrementPostViewCount: (_ postID: String) async throws -> BaseResponse
    
    enum PostAPI: APITarget {
        case createPost(request: CreatePostRequest)
        case fetchNearPosts(request: FetchNearPostsRequest)
        case fetchPostByID(id: String)
        case incrementPostViewCount(postID: String)
        
        var method: HTTPMethod {
            switch self {
            case .fetchNearPosts: .get
            case .fetchPostByID: .get
            case .createPost: .post
            case .incrementPostViewCount: .post
            }
        }
        
        var body: (any Encodable)? {
            switch self {
            case .createPost(let request): request
            case .fetchNearPosts: nil
            case .fetchPostByID: nil
            case .incrementPostViewCount: nil
            }
        }
        
        var headers: [String : String] {
            var headers: [String: String] = [:]
            
            @Dependency(\.keychain) var keychain
            
            switch self {
            case .incrementPostViewCount:
                let idToken = try? keychain.load(service: .firebase, account: .idToken)
                headers["Authorization"] = "Bearer \(idToken ?? "")"
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
            case let .incrementPostViewCount(postID):
                "/increasePostViewCount/posts/\(postID)/views"
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
        } incrementPostViewCount: { postID in
            try await Client.request(target: PostAPI.incrementPostViewCount(postID: postID))
        }
    }
    
    static var testValue: PostClient {
        PostClient { _ in
            return .stub()
        } fetchNearPosts: { _ in
            return FetchNearPostsResponse(posts: [.stub()], geohashBlocks: ["a", "b", "c"])
        } fetchPostByID: { _ in
            return .stub()
        } incrementPostViewCount: { _ in
            BaseResponse(status: "status", message: "message")
        }

    }
}

extension DependencyValues {
    var postClient: PostClient {
        get { self[PostClient.self] }
        set { self[PostClient.self] = newValue }
    }
}



