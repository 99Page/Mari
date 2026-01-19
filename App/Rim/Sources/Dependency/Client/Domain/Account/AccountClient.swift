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
import Core
import ComposableArchitecture

@DependencyClient
struct AccountClient {
    var signInUsingApple: (_ token: String, _ nonce: String) async throws -> SignInResult
    var logout: () throws -> Void
    var isLoggedIn: () -> Bool = { false }
    var signInFirebase: (_ credential: AuthCredential) async throws -> SignInResult
    var refreshIdToken: () async throws -> Void
    var withdraw: () async throws -> APIResponse<EmptyResult>
    
    // 로그아웃이 필요한 상황에서 호출. 예시) uid 가 없음
    var triggerLogout:  @Sendable () -> Void
    
    // 이벤트 구독 스트림
    var delegate: @Sendable () -> AsyncStream<Delegate> = { .finished }
    
    @CasePathable
    enum Delegate {
        case logoutRequired
    }
    
    enum AccountAPI: APITarget {
        case withdraw
        
        var method: HTTPMethod {
            switch self {
            case .withdraw: .post
            }
        }
        
        var body: (any Encodable)? {
            switch self {
            case .withdraw: nil
            }
        }
        
        var headers: [String : String] {
            @Dependency(\.keychain) var keychain
            var headers: [String: String] = [:]
            
            switch self {
            case .withdraw:
                let idToken = try? keychain.load(service: .firebase, account: .idToken)
                headers["Authorization"] = "Bearer \(idToken ?? "")"
            }
            
            return headers
        }
        
        var baseURLString: String { functionsURL }
        
        var path: String {
            switch self {
            case .withdraw: "/withdrawAccount"
            }
        }
    }
}

extension AccountClient: DependencyKey {
    static var liveValue: AccountClient {
        let (stream, continuation) = AsyncStream.makeStream(of: Delegate.self)
        
        let signIn: (_ credential: AuthCredential) async throws -> SignInResult = { credential in
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
            
            let uid = authData.user.uid
            let idToken = try await authData.user.getIDToken()
            return SignInResult(uid: uid, idToken: idToken)
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
        } withdraw: {
            try await Client.request(target: AccountAPI.withdraw)
        } triggerLogout: {
            continuation.yield(.logoutRequired)
        } delegate: { stream }
    }
    
    static let testValue = Self(
        signInUsingApple: unimplemented("\(Self.self).signInUsingApple"),
        logout: unimplemented("\(Self.self).logout"),
        isLoggedIn: unimplemented("\(Self.self).isLoggedIn", placeholder: false),
        signInFirebase: unimplemented("\(Self.self).signInFirebase"),
        refreshIdToken: unimplemented("\(Self.self).refreshIdToken"),
        withdraw: unimplemented("\(Self.self).withdraw"),
        triggerLogout: unimplemented("\(Self.self).triggerLogout"),
        delegate: unimplemented("\(Self.self).delegate", placeholder: .finished)
    )
}

extension DependencyValues {
    var accountClient: AccountClient {
        get { self[AccountClient.self] }
        set { self[AccountClient.self] = newValue }
    }
}
