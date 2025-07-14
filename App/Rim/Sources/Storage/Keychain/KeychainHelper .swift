//
//  KeychainHelper .swift
//  Rim
//
//  Created by 노우영 on 7/1/25.
//

import Foundation
import Security
import Dependencies
import DependenciesMacros

enum KeychainService: String {
    case firebase
}

enum KeychainAccount: String {
    case idToken
    case userID
}

final class KeychainHelper {

    @discardableResult
    static func save(value: String, service: KeychainService, account: KeychainAccount) -> Bool {
        guard let data = value.data(using: .utf8) else { return false }

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service.rawValue,
            kSecAttrAccount as String: account.rawValue,
            kSecValueData as String: data
        ]

        SecItemDelete(query as CFDictionary)
        let status = SecItemAdd(query as CFDictionary, nil)

        return status == errSecSuccess
    }

    static func load(service: KeychainService, account: KeychainAccount) throws -> String {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service.rawValue,
            kSecAttrAccount as String: account.rawValue,
            kSecReturnData as String: kCFBooleanTrue!,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var dataTypeRef: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &dataTypeRef)

        if status == errSecSuccess,
           let retrievedData = dataTypeRef as? Data,
           let value = String(data: retrievedData, encoding: .utf8) {
            return value
        }

        throw ClientError.emptyValue
    }

    static func delete(service: KeychainService, account: KeychainAccount) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service.rawValue,
            kSecAttrAccount as String: account.rawValue
        ]

        let _ = SecItemDelete(query as CFDictionary)
    }
}

@DependencyClient
struct KeychainClient {
    var save: (_ value: String, _ service: KeychainService, _ account: KeychainAccount) throws -> Void = { _, _, _ in }
    var load: (_ service: KeychainService, _ account: KeychainAccount) throws -> String
    var delete: (_ service: KeychainService, _ account: KeychainAccount) -> Void = { _, _ in }
}

extension KeychainClient: DependencyKey {
    static var liveValue: KeychainClient {
        KeychainClient(
            save: { value, service, account in
                KeychainHelper.save(value: value, service: service, account: account)
            },
            load: { service, account in
                try KeychainHelper.load(service: service, account: account)
            },
            delete: { service, account in
                KeychainHelper.delete(service: service, account: account)
            }
        )
    }
    
    static var testValue: KeychainClient {
        KeychainClient { value, service, account in
            
        } load: { service, account in
            return "keychain value"
        } delete: { service, account in
            
        }

    }
}

extension DependencyValues {
    var keychain: KeychainClient {
        get { self[KeychainClient.self] }
        set { self[KeychainClient.self] = newValue }
    }
}
