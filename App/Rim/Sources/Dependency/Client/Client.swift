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

protocol APITarget {
    var method: HTTPMethod { get }
    var body: Encodable? { get }
    var headers: [String: String] { get }
    var baseURLString: String { get }
    var path: String { get }
}

extension APITarget {
    var url: URL? {
        URL(string: "\(baseURLString)\(path)")
    }
}

class Client {
    static func request<T: Decodable>(target: APITarget) async throws -> T {
        guard let url = target.url else { throw ClientError.invalidURL }
        
        var request = URLRequest(url: url)
        request.httpMethod = target.method.rawValue

        target.headers.forEach { key, value in
            request.setValue(value, forHTTPHeaderField: key)
        }

        if let body = target.body {
            request.httpBody = try JSONEncoder().encode(body)
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }

        let (data, response) = try await URLSession.shared.data(for: request)

        try validateHTTPResponse(response, data: data)

        return try JSONDecoder().decode(T.self, from: data)
    }

    private static func validateHTTPResponse(_ response: URLResponse, data: Data) throws {
        guard let httpResponse = response as? HTTPURLResponse else {
            throw ClientError.invalidResponse
        }

        if !(200...299).contains(httpResponse.statusCode) {
            if let errorResponse = try? JSONDecoder().decode(ErrorResponse.self, from: data) {
                throw errorResponse
            } else {
                throw ClientError.failDecoding
            }
        }
    }
}
