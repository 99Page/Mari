//
//  SceneFeatureTests.swift
//  RimTests
//
//  Created by 노우영 on 6/27/25.
//

import Testing
import ComposableArchitecture
@testable import Rim

@MainActor
struct SceneFeatureTests {

    @Test func showLoginView_whenLogoutSucceeded() async throws {
        let store: TestStoreOf<SceneFeature> = TestStore(initialState: SceneFeature.State.tab(.init())) {
            SceneFeature()
        } withDependencies: {
            $0.accountClient.logout = { } // 로그아웃 성공
        }
        
        await store.send(.tab(.userAccount(.view(.logoutButtonTapped))))
        await store.receive(\.tab.userAccount.delegate) {
            $0 = .login(.init())
        }
    }
    
    @Test func showTabView_whenLoginSucceeded() async throws {
        let store: TestStoreOf<SceneFeature> = TestStore(initialState: SceneFeature.State.login(.init())) {
            SceneFeature()
        }
        
        await store.send(.login(.delegate(.signInSucceeded))) {
            $0 = .tab(.init())
        }
    }
}
