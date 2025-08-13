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
    var fetchBlockedUserIds: () async throws -> APIResponse<BlockedUserIdsResponse>
    
    enum UserRelationAPI: APITarget {
        case blocksUser(userId: String?)
        case fetchBlockedUserIds
        
        var method: HTTPMethod {
            switch self {
            case .blocksUser: .post
            case .fetchBlockedUserIds: .get
            }
        }
        
        var body: (any Encodable)? {
            switch self {
            case .blocksUser(let userId):
                return ["targetUserId": userId]
            case .fetchBlockedUserIds: return nil
            }
        }
        
        var headers: [String : String] {
            @Dependency(\.keychain) var keychain
            var headers: [String: String] = [:]
            
            switch self {
            case .blocksUser, .fetchBlockedUserIds:
                let idToken = try? keychain.load(service: .firebase, account: .idToken)
                headers["Authorization"] = "Bearer \(idToken ?? "")"
            }
            
            return headers
        }
        
        var baseURLString: String { functionsURL }
         
        var path: String {
            switch self {
            case .blocksUser: "/blocksUser"
            case .fetchBlockedUserIds: "/fetchBlockedUserIds"
            }
        }
    }
}

extension UserRelationClient: DependencyKey {
    static var liveValue: UserRelationClient {
        UserRelationClient { targetUserId in
            try await Client.request(target: UserRelationAPI.blocksUser(userId: targetUserId))
        } fetchBlockedUserIds: {
            try await Client.request(target: UserRelationAPI.fetchBlockedUserIds)
        }
    }
    
    static var testValue: UserRelationClient {
        UserRelationClient { _ in
            return .stub()
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
