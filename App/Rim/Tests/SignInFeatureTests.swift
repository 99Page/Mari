//
//  LoginFeatureTests.swift
//  RimTests
//
//  Created by 노우영 on 7/10/25.
//

import Testing
import ComposableArchitecture
@testable import Rim

@MainActor
struct SignInFeatureTests {

    @Test func test_saveUID_AfterAppleSignIn() async throws {
        let store = TestStore(initialState: SignInFeature.State()) {
            SignInFeature()
        } withDependencies: {
            $0.accountClient.signInUsingApple = { _, _ in
                SignInResult(uid: "uid", idToken: "idToken")
            }
        }
        
        store.exhaustivity = .off
        await store.send(.view(.appleSignInSucceeded(identityToken: "")))
        #expect(store.state.$uid.wrappedValue == "uid")
    }

}
