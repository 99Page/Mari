//
//  Client.swift
//  Rim
//
//  Created by 노우영 on 6/23/25.
//

import Foundation

enum HTTPMethod: String {
    case get = "GET"
    case post = "POST"
    // Extend as needed (PUT, DELETE, etc.)
}

class Client {
    static func request<T: Decodable>(
        url: URL,
        method: HTTPMethod = .get,
        body: Encodable? = nil,
        headers: [String: String] = [:]
    ) async throws -> T {
        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue

        headers.forEach { key, value in
            request.setValue(value, forHTTPHeaderField: key)
        }

        if let body = body {
            request.httpBody = try JSONEncoder().encode(body)
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }

        let (data, _) = try await URLSession.shared.data(for: request)
        debugPrint(data)
        return try JSONDecoder().decode(T.self, from: data)
    }
}
