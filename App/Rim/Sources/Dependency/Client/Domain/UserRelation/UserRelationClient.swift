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
    var blocksUser: (_ userId: String?) async throws -> APIResponse<EmptyResult>
    
    enum UserRelationAPI: APITarget {
        case blocksUser(userId: String?)
        
        var method: HTTPMethod {
            switch self {
            case .blocksUser: .post
            }
        }
        
        var body: (any Encodable)? {
            switch self {
            case .blocksUser(let userId):
                return ["targetUserId": userId]
            }
        }
        
        var headers: [String : String] {
            @Dependency(\.keychain) var keychain
            var headers: [String: String] = [:]
            
            switch self {
            case .blocksUser:
                let idToken = try? keychain.load(service: .firebase, account: .idToken)
                headers["Authorization"] = "Bearer \(idToken ?? "")"
            }
            
            return headers
        }
        
        var baseURLString: String { functionsURL }
         
        var path: String {
            switch self {
            case .blocksUser:
                "/blocksUser"
            }
        }
    }
}

extension UserRelationClient: DependencyKey {
    static var liveValue: UserRelationClient {
        UserRelationClient { targetUserId in
            try await Client.request(target: UserRelationAPI.blocksUser(userId: targetUserId))
        }
    }
}

extension DependencyValues {
    var userRelationClient: UserRelationClient {
        get { self[UserRelationClient.self] }
        set { self[UserRelationClient.self] = newValue }
    }
}
