//
//  BaseResponse.swift
//  Rim
//
//  Created by 노우영 on 7/14/25.
//

import Foundation

struct APIResponse<Data: Decodable & Stub>: Decodable, Stub {
    let status: String
    let message: String
    let result: Data
    
    static func stub() -> Self {
        Self(status: "status", message: "message", result: .stub())
    }
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

struct ErrorResponse: Decodable, Error, LocalizedError, CustomStringConvertible {
    let code: String
    let message: String

    var description: String { "code: \(code), message: \(message)" }

    var errorDescription: String? { description }
}
