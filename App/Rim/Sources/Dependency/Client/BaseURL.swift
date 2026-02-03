//
//  BaseURL.swift
//  Rim
//
//  Created by 노우영 on 6/23/25.
//

import Foundation

struct APIConfig {
    static let baseURL: String = {
        guard let urlString = Bundle.main.infoDictionary?["BASE_URL"] as? String else {
            assertionFailure("🚨 Critical: BASE_URL not set in Info.plist")
            return ""
        }
        return urlString
    }()
    
    static let v2URL: String = "\(baseURL)/api/v2"
    static let v3URL: String = "\(baseURL)/api/v3"
    static let functionsURL: String = baseURL
}
