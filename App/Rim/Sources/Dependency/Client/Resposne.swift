//
//  BaseResponse.swift
//  Rim
//
//  Created by 노우영 on 7/14/25.
//

import Foundation

struct APIResponse<Data: Decodable & Stub>: Decodable {
    let status: String
    let message: String
    let result: Data
}

protocol Stub {
    static func stub() -> Self
}

struct EmptyResult: Decodable, Stub {
    static func stub() -> Self { EmptyResult() }
}

extension Array: Stub where Element: Stub {
    static func stub() -> Self {
        [.stub(), .stub(), .stub()]
    }
}

struct ErrorResponse: Decodable, Error {
    let code: String
    let message: String
}
