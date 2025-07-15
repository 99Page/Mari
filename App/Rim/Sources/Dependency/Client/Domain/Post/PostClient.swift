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
    var incrementPostViewCount: (_ postID: String) async throws -> APIResponse<EmptyResult>
    // lastCreateAt는 커서의 역할을 합니다 -page, 2025. 07. 15
    var fetchUserPosts: (_ lastCreatedAt: Date) async throws -> APIResponse<Array<PostDTO>>
    
    enum PostAPI: APITarget {
        case createPost(request: CreatePostRequest)
        case fetchNearPosts(request: FetchNearPostsRequest)
        case fetchPostByID(id: String)
        case incrementPostViewCount(postID: String)
        case fetchUserPosts(lastCreatedAt: Date)
        
        var method: HTTPMethod {
            switch self {
            case .fetchNearPosts: .get
            case .fetchPostByID: .get
            case .createPost: .post
            case .incrementPostViewCount: .post
            case .fetchUserPosts: .get
            }
        }
        
        var body: (any Encodable)? {
            switch self {
            case .createPost(let request): request
            case .fetchNearPosts: nil
            case .fetchPostByID: nil
            case .incrementPostViewCount: nil
            case .fetchUserPosts: nil
            }
        }
        
        var headers: [String : String] {
            var headers: [String: String] = [:]
            
            @Dependency(\.keychain) var keychain
            
            switch self {
            case .incrementPostViewCount, .createPost, .fetchUserPosts:
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
            case let .fetchUserPosts(lastCreatedAt):
                "/getPostsByUser?lastCreatedAt=\(lastCreatedAt)"
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
        } fetchUserPosts: { lastCreatedAt in
            try await Client.request(target: PostAPI.fetchUserPosts(lastCreatedAt: lastCreatedAt))
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
            APIResponse(status: "status", message: "message", result: .stub())
        } fetchUserPosts: { _  in
            APIResponse(status: "status", message: "message", result: .stub())
        }

    }
}

extension DependencyValues {
    var postClient: PostClient {
        get { self[PostClient.self] }
        set { self[PostClient.self] = newValue }
    }
}



