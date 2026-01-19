//
//  VersionUtils.swift
//  Rim
//
//  Created by 노우영 on 1/18/26.
//

import Foundation

struct VersionUtils {
    static var appVersion: String {
        return Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
    }
    
    static func isUpdateRequired(minVersion: String) -> Bool {
        let result = appVersion.compare(minVersion, options: .numeric)
        return result == .orderedAscending
    }
}
