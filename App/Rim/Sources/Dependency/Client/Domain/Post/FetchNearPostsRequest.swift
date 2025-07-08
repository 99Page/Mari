//
//  FetchNearPostsRequest.swift
//  Rim
//
//  Created by 노우영 on 7/1/25.
//

import Foundation

struct FetchNearPostsRequest: Encodable {
    let type: String
    let latitude: Double
    let longitude: Double
    let precision: Int
}
