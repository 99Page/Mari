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
    var createPost: (_ request: Request.Post) async throws -> APIResponse<PostDetailDTO>
    
    var fetchMapPosts: (_ request: Request.GetMapPost) async throws -> APIResponse<Response.MapPosts>
    
    var fetchNearPosts: () async throws -> APIResponse<FetchNearPostsResponse>
    
    var fetchPostByID: (_ id: String) async throws -> APIResponse<PostDetailDTO>
    
    var incrementPostViewCount: (_ postID: String) async throws -> APIResponse<EmptyResult>
    
    // lastCreatedAt는 커서의 역할을 합니다 -page, 2025. 07. 15
    var fetchUserPosts: (_ lastCreatedAt: Date) async throws -> APIResponse<FetchUserPostsResponse>
    
    var deletePost: (_ postID: String) async throws -> APIResponse<DeletePostResponse>
    
    var report: (_ postID: String) async throws -> APIResponse<EmptyResult>
    
    enum PostAPI: APITarget {
        case createPost(request: PostRequest.Post)
        case fetchMapPosts(request: PostRequest.GetMapPost )
        case fetchPostByID(id: String)
        case incrementPostViewCount(postID: String)
        case fetchUserPosts(lastCreatedAt: Date)
        case deletePost(postID: String)
        case report(postID: String)
        
        var method: HTTPMethod {
            switch self {
            case .fetchMapPosts: .get
            case .fetchPostByID: .get
            case .createPost, .report, .incrementPostViewCount: .post
            case .fetchUserPosts: .get
            case .deletePost: .delete
            }
        }
        
        var body: (any Encodable)? {
            switch self {
            case .createPost(let request): request
            case .fetchMapPosts: nil
            case .fetchPostByID: nil
            case .incrementPostViewCount: nil
            case .fetchUserPosts: nil
            case .deletePost: nil
            case let .report(postId):
                ["postId": postId]
            }
        }
        
        var headers: [String : String] {
            var headers: [String: String] = [:]
            
            @Dependency(\.keychain) var keychain
            
            switch self {
            case .incrementPostViewCount, .createPost, .fetchUserPosts, .deletePost, .fetchPostByID, .report:
                let idToken = try? keychain.load(service: .firebase, account: .idToken)
                headers["Authorization"] = "Bearer \(idToken ?? "")"
            case .fetchMapPosts:
                break
            }
            return headers
        }
        
        var baseURLString: String {
            switch self {
            case .fetchMapPosts: v2URL
            default: functionsURL
            }
        }
        
        var path: String {
            switch self {
            case .createPost: "/v2/posts"
            case let .fetchMapPosts(request):
                "/posts/?latitude=\(request.latitude)&longitude=\(request.longitude)&precision=\(request.precision)&type=\(request.type)&groupSize=\(request.groupSize)"
            case let .fetchPostByID(id): "/getPostById?id=\(id)"
            case let .incrementPostViewCount(postID):
                "/increasePostViewCount/posts/\(postID)/views"
            case let .fetchUserPosts(lastCreatedAt):
                "/getPostsByUser?lastCreatedAt=\(lastCreatedAt)"
            case let .deletePost(postID):
                "/deletePost?id=\(postID)"
            case .report:
                "/reportPost"
            }
        }
    }
}

extension PostClient: DependencyKey {
    static var liveValue: PostClient {
        PostClient { request in
            try await Client.request(target: PostAPI.createPost(request: request))
        } fetchMapPosts: { request in
            try await Client.request(target: PostAPI.fetchMapPosts(request: request))
        } fetchNearPosts: {
            throw ErrorResponse(code: "", message: "")
        } fetchPostByID: { id in
            try await Client.request(target: PostAPI.fetchPostByID(id: id))
        } incrementPostViewCount: { postID in
            try await Client.request(target: PostAPI.incrementPostViewCount(postID: postID))
        } fetchUserPosts: { lastCreatedAt in
            try await Client.request(target: PostAPI.fetchUserPosts(lastCreatedAt: lastCreatedAt))
        } deletePost: { postID in
            try await Client.request(target: PostAPI.deletePost(postID: postID))
        } report: { postID in
            try await Client.request(target: PostAPI.report(postID: postID))
        }
    }
    
    static var testValue: PostClient {
        PostClient { _ in
                .stub()
        } fetchMapPosts: { request in
                .stub()
        } fetchNearPosts: {
                .stub()
        } fetchPostByID: { _ in
                .stub()
        } incrementPostViewCount: { _ in
            APIResponse(status: "status", message: "message", result: .stub())
        } fetchUserPosts: { _  in
            APIResponse(status: "status", message: "message", result: .stub())
        } deletePost: { _ in
                .stub()
        } report: { _ in
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



