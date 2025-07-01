//
//  ClientError.swift
//  Rim
//
//  Created by 노우영 on 6/18/25.
//

import Foundation

enum ClientError: Error {
    case unwrappingFailed
    case invalidURL
    case firebaseError
    case emptyValue
}
