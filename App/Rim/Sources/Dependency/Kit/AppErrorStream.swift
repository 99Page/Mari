//
//  AppErrorObserver.swift
//  Rim
//
//  Created by 노우영 on 7/11/25.
//

import Foundation
import Dependencies
import DependenciesMacros

@DependencyClient
struct AppErrorStream {
    var stream: () async -> AsyncStream<AppError> = { .finished }
}

enum AppError: String {
    case emptyUID
}

extension AppErrorStream: DependencyKey {
    static var liveValue: AppErrorStream {
        AppErrorStream {
            AsyncStream { continuation in
                let observer = NotificationCenter.default.addObserver(
                    forName: .appErrorNotification,
                    object: nil,
                    queue: .main
                ) { notification in
                    if let error = notification.object as? AppError {
                        continuation.yield(error)
                    }
                }
                
                continuation.onTermination = { _ in
                    NotificationCenter.default.removeObserver(observer)
                }
            }
        }
    }
    
    static var testValue: AppErrorStream {
        liveValue
    }
}

extension Notification.Name {
    static let appErrorNotification = Notification.Name("AppErrorNotification")
}

extension DependencyValues {
    var appErrorStream: AppErrorStream {
        get { self[AppErrorStream.self] }
        set { self[AppErrorStream.self] = newValue }
    }
}
