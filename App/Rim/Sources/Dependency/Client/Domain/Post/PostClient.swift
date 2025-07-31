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
    var createPost: (_ request: CreatePostRequest) async throws -> APIResponse<PostDetailDTO>
    var fetchNearPosts: (_ request: FetchNearPostsRequest) async throws -> APIResponse<FetchNearPostsResponse>
    var fetchPostByID: (_ id: String) async throws -> APIResponse<PostDetailDTO>
    var incrementPostViewCount: (_ postID: String) async throws -> APIResponse<EmptyResult>
    // lastCreateAt는 커서의 역할을 합니다 -page, 2025. 07. 15
    var fetchUserPosts: (_ lastCreatedAt: Date) async throws -> APIResponse<FetchUserPostsResponse>
    var deletePost: (_ postID: String) async throws -> APIResponse<DeletePostResponse>
    
    enum PostAPI: APITarget {
        case createPost(request: CreatePostRequest)
        case fetchNearPosts(request: FetchNearPostsRequest)
        case fetchPostByID(id: String)
        case incrementPostViewCount(postID: String)
        case fetchUserPosts(lastCreatedAt: Date)
        case deletePost(postID: String)
        
        var method: HTTPMethod {
            switch self {
            case .fetchNearPosts: .get
            case .fetchPostByID: .get
            case .createPost: .post
            case .incrementPostViewCount: .post
            case .fetchUserPosts: .get
            case .deletePost: .delete
            }
        }
        
        var body: (any Encodable)? {
            switch self {
            case .createPost(let request): request
            case .fetchNearPosts: nil
            case .fetchPostByID: nil
            case .incrementPostViewCount: nil
            case .fetchUserPosts: nil
            case .deletePost: nil
            }
        }
        
        var headers: [String : String] {
            var headers: [String: String] = [:]
            
            @Dependency(\.keychain) var keychain
            
            switch self {
            case .incrementPostViewCount, .createPost, .fetchUserPosts, .deletePost, .fetchPostByID:
                let idToken = try? keychain.load(service: .firebase, account: .idToken)
                headers["Authorization"] = "Bearer \(idToken ?? "")"
            case .fetchNearPosts:
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
            case let .deletePost(postID):
                "/deletePost?id=\(postID)"
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
        } deletePost: { postID in
            try await Client.request(target: PostAPI.deletePost(postID: postID))
        }
    }
    
    static var testValue: PostClient {
        PostClient { _ in
            return .stub()
        } fetchNearPosts: { _ in
                .stub()
        } fetchPostByID: { _ in
            return .stub()
        } incrementPostViewCount: { _ in
            APIResponse(status: "status", message: "message", result: .stub())
        } fetchUserPosts: { _  in
            APIResponse(status: "status", message: "message", result: .stub())
        } deletePost: { _ in
                .stub()
        }
    }
    
    static var previewValue: PostClient { testValue }
}

extension DependencyValues {
    var postClient: PostClient {
        get { self[PostClient.self] }
        set { self[PostClient.self] = newValue }
    }
}



