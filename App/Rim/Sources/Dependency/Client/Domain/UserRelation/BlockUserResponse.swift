//
//  BlockUserResponse.swift
//  Rim
//
//  Created by 노우영 on 8/13/25.
//

import Foundation

struct BlockUserResponse: Decodable, Stub {
    let blocked: Bool
    let relationshipId: String
    
    static func stub() -> BlockUserResponse {
        BlockUserResponse(blocked: true, relationshipId: "userId")
    }
}
