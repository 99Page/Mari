//
//  Client.swift
//  Rim
//
//  Created by 노우영 on 6/23/25.
//

import Foundation
import Core

enum HTTPMethod: String {
    case get = "GET"
    case post = "POST"
    case delete
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

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601WithMilliseconds
        
        return try decoder.decode(T.self, from: data)
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

extension JSONDecoder.DateDecodingStrategy {
    static var iso8601WithMilliseconds: JSONDecoder.DateDecodingStrategy {
        return .custom { decoder in
            let container = try decoder.singleValueContainer()
            let dateStr = try container.decode(String.self)
            
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            
            guard let date = formatter.date(from: dateStr) else {
                throw DecodingError.dataCorruptedError(
                    in: container,
                    debugDescription: "Expected ISO8601 date string with fractional seconds"
                )
            }
            return date
        }
    }
}
