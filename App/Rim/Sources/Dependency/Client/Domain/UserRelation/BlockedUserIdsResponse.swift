//
//  BlockedUserIdsResponse.swift
//  Rim
//
//  Created by 노우영 on 8/13/25.
//

import Foundation

struct BlockedUserIdsResponse: Decodable, Stub {
    let blockedUserIds: [String]
    
    static func stub() -> BlockedUserIdsResponse {
        BlockedUserIdsResponse(blockedUserIds: ["id1"])
    }
}
