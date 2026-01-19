//
//  AppUpdateClient.swift
//  Rim
//
//  Created by 노우영 on 1/18/26.
//

import ComposableArchitecture
import FirebaseRemoteConfig
import UIKit

@DependencyClient
struct AppUpdateClient {
    var checkUpdateRequirement: () async throws -> Bool
    var openAppStore: () async -> Void
}

extension AppUpdateClient: DependencyKey {
    static let liveValue: AppUpdateClient = {
        return AppUpdateClient(
            checkUpdateRequirement: {
                let remoteConfig = RemoteConfig.remoteConfig()
                let settings = RemoteConfigSettings()
                settings.minimumFetchInterval = 3600
                remoteConfig.configSettings = settings
                
                let status = try await remoteConfig.fetchAndActivate()
                
                let minVersionString = remoteConfig.configValue(forKey: "min_required_version").stringValue
                let minVersion = minVersionString.trimmingCharacters(in: .whitespacesAndNewlines)
                let currentVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
                
                return currentVersion.compare(minVersion, options: .numeric) == .orderedAscending
            },
            openAppStore: {
                await MainActor.run {
                    guard let url = URL(string: "itms-apps://itunes.apple.com/app/id6747739730") else { return }
                    UIApplication.shared.open(url)
                }
            }
        )
    }()
}

extension DependencyValues {
    var appUpdateClient: AppUpdateClient {
        get { self[AppUpdateClient.self] }
        set { self[AppUpdateClient.self] = newValue }
    }
}
