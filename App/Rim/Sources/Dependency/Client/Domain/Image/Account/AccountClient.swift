//
//  AccountClient.swift
//  Rim
//
//  Created by 노우영 on 6/25/25.
//

import Foundation
import Dependencies
import DependenciesMacros
import UIKit
import FirebaseAuth
import FirebaseCore
import GoogleSignIn

@DependencyClient
struct AccountClient {
    var loginUsingApple: (_ token: String, _ nonce: String) async throws -> AuthDataResult
    var logout: () throws -> Void
    var isLoggedIn: () -> Bool = { false }
    var signInFirebase: (_ credential: AuthCredential) async throws -> AuthDataResult
    var refreshIdToken: () async throws -> Void
}

extension AccountClient: DependencyKey {
    static var liveValue: AccountClient {
        let signIn: (_ credential: AuthCredential) async throws -> AuthDataResult = { credential in
            let authData: AuthDataResult? = try await withCheckedThrowingContinuation { continuation in
                Auth.auth().signIn(with: credential) { result, error in
                    if let error = error {
                        continuation.resume(throwing: error)
                        return
                    }
                    continuation.resume(returning: result)
                }
            }
            guard let authData else { throw ClientError.emptyValue }
            return authData
        }
        
        return AccountClient { token, nonce in
            let credential = OAuthProvider.credential(
                providerID: .apple,
                idToken: token,
                rawNonce: nonce,
                accessToken: nil
            )
            return try await signIn(credential)
        } logout: {
            @Dependency(\.keychain) var keychain
            let firebaseAuth = Auth.auth()
            try firebaseAuth.signOut()
            keychain.delete(service: .firebase, account: .idToken)
        } isLoggedIn: {
            return Auth.auth().currentUser != nil
        } signInFirebase: { credential in
            try await signIn(credential)
        } refreshIdToken: {
            let idToken = try await Auth.auth().currentUser?.getIDToken(forcingRefresh: true)
            @Dependency(\.keychain) var keychain
            guard let idToken else { throw ClientError.emptyToken }
            try keychain.save(value: idToken, service: .firebase, account: .idToken)
        }
    }
}

extension DependencyValues {
    var accountClient: AccountClient {
        get { self[AccountClient.self] }
        set { self[AccountClient.self] = newValue }
    }
}
