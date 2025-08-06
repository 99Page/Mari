//
//  DeletePostResponse.swift
//  Rim
//
//  Created by 노우영 on 7/15/25.
//

import Foundation

struct DeletePostResponse: Decodable, Stub {
    let id: String
    
    static func stub() -> Self {
        .init(id: "1")
    }
}
