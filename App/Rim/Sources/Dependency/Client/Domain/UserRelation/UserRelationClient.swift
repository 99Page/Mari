//
//  UserRelationClient.swift
//  Rim
//
//  Created by 노우영 on 8/11/25.
//

import Foundation
import Dependencies
import DependenciesMacros

@DependencyClient
struct UserRelationClient {
    var blocksUser: (_ userId: String?) async throws -> APIResponse<BlockUserResponse>
    var unblocksUser: (_ userId: String?) async throws -> APIResponse<BlockUserResponse>
    var fetchBlockedUserIds: () async throws -> APIResponse<BlockedUserIdsResponse>
    
    enum UserRelationAPI: APITarget {
        case blocksUser(userId: String?)
        case unblocksUser(userId: String?)
        case fetchBlockedUserIds
        
        var method: HTTPMethod {
            switch self {
            case .blocksUser: .post
            case .unblocksUser: .delete
            case .fetchBlockedUserIds: .get
            }
        }
        
        var body: (any Encodable)? {
            switch self {
            case let .blocksUser(userId), let .unblocksUser(userId):
                return ["targetUserId": userId]
            case .fetchBlockedUserIds: return nil
            }
        }
        
        var headers: [String : String] {
            @Dependency(\.keychain) var keychain
            var headers: [String: String] = [:]
            
            switch self {
            case .blocksUser, .fetchBlockedUserIds, .unblocksUser:
                let idToken = try? keychain.load(service: .firebase, account: .idToken)
                headers["Authorization"] = "Bearer \(idToken ?? "")"
            }
            
            return headers
        }
        
        var baseURLString: String { functionsURL }
         
        var path: String {
            switch self {
            case .blocksUser: "/blocksUser"
            case .unblocksUser: "/unblocksUser"
            case .fetchBlockedUserIds: "/fetchBlockedUserIds"
            }
        }
    }
}

extension UserRelationClient: DependencyKey {
    static var liveValue: UserRelationClient {
        UserRelationClient { targetUserId in
            try await Client.request(target: UserRelationAPI.blocksUser(userId: targetUserId))
        } unblocksUser: { userId in
            try await Client.request(target: UserRelationAPI.unblocksUser(userId: userId))
        } fetchBlockedUserIds: {
            try await Client.request(target: UserRelationAPI.fetchBlockedUserIds)
        }
    }
    
    static var testValue: UserRelationClient {
        UserRelationClient { _ in
            return .stub()
        } unblocksUser: { userId in
            return .init(status: "", message: "", result: .init(blocked: false, relationshipId: "id"))
        } fetchBlockedUserIds: {
            return .stub()
        }

    }
}

extension DependencyValues {
    var userRelationClient: UserRelationClient {
        get { self[UserRelationClient.self] }
        set { self[UserRelationClient.self] = newValue }
    }
}
