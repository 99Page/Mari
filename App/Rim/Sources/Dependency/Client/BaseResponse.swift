//
//  BaseResponse.swift
//  Rim
//
//  Created by 노우영 on 7/14/25.
//

import Foundation

struct BaseResponse: Decodable {
    let status: String
    let message: String
}
