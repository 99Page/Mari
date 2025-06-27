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
    var loginUsingApple: (_ token: String, _ nonce: String) async throws -> Void
    var logout: () throws -> Void
    var isLoggedIn: () -> Bool = { false }
}

extension AccountClient: DependencyKey {
    static var liveValue: AccountClient {
        AccountClient { token, nonce in
            // https://firebase.google.com/docs/auth/ios/apple?hl=ko
            let credential = OAuthProvider.credential(
                providerID: .apple,
                idToken: token,
                rawNonce: nonce,
                accessToken: nil
            )
            
            let _: AuthDataResult? = try await withCheckedThrowingContinuation { continuation in
                Auth.auth().signIn(with: credential) { result, error in
                    if let error = error {
                        continuation.resume(throwing: error)
                        return
                    }
                    
                    continuation.resume(returning: result)
                }
            }
        } logout: {
            // https://firebase.google.com/docs/auth/ios/apple?hl=ko#next-steps
            let firebaseAuth = Auth.auth()
            try firebaseAuth.signOut()
        } isLoggedIn: {
            return Auth.auth().currentUser != nil
        }
    }
}

extension DependencyValues {
    var accountClient: AccountClient {
        get { self[AccountClient.self] }
        set { self[AccountClient.self] = newValue }
    }
}
