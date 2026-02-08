//
//  ErrorReportClient.swift
//  Rim
//
//  Created for Firebase error tracking.
//

import Foundation
import Dependencies
import DependenciesMacros
import Core

@DependencyClient
struct ErrorReportClient {
    /// Sends an error report to the server (Firestore errorLogs with source "ios").
    /// Optional: call from catch blocks; failures are not propagated.
    var reportError: (_ context: String, _ message: String, _ code: String?) async throws -> Void
}

extension ErrorReportClient {
    enum ErrorReportAPI: APITarget {
        case report(context: String, message: String, code: String?)

        var method: HTTPMethod { .post }

        var body: (any Encodable)? {
            switch self {
            case let .report(context, message, code):
                struct Body: Encodable {
                    let context: String
                    let message: String
                    let code: String?
                }
                return Body(context: context, message: message, code: code)
            }
        }

        var headers: [String: String] {
            @Dependency(\.keychain) var keychain
            var h: [String: String] = ["Content-Type": "application/json"]
            if let token = try? keychain.load(service: .firebase, account: .idToken) {
                h["Authorization"] = "Bearer \(token)"
            }
            return h
        }

        var baseURLString: String { APIConfig.v3URL }

        var path: String { "/errors" }
    }
}

private struct ReportErrorResponse: Decodable {
    let status: String
}

extension ErrorReportClient: DependencyKey {
    static var liveValue: ErrorReportClient {
        ErrorReportClient { context, message, code in
            let _: ReportErrorResponse = try await Client.request(
                target: ErrorReportAPI.report(context: context, message: message, code: code)
            )
        }
    }

    static var testValue: ErrorReportClient {
        ErrorReportClient(reportError: unimplemented("\(Self.self).reportError"))
    }
}

extension DependencyValues {
    var errorReportClient: ErrorReportClient {
        get { self[ErrorReportClient.self] }
        set { self[ErrorReportClient.self] = newValue }
    }
}
