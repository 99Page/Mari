//
//  SceneFeatureTests.swift
//  RimTests
//
//  Created by 노우영 on 6/27/25.
//

import Testing
import ComposableArchitecture
import UIKit
@testable import Rim


@MainActor
struct RootFeatureTests {

    @Test func showLoginView_whenLogoutSucceeded() async throws {
        let store: TestStoreOf<RootFeature> = TestStore(initialState: RootFeature.State(destination: .tab(.init()))) {
            RootFeature()
        } withDependencies: {
            $0.accountClient.logout = { } // 로그아웃 성공
            $0.continuousClock = ImmediateClock()
        }
        
        await store.send(.destination(.tab(.userAccount(.view(.logoutButtonTapped)))))
        await store.receive(\.destination.tab.userAccount.delegate.logout)
        await store.receive(\.signOut) {
            $0.destination = .signIn(.init())
        }
    }
    
    @Test func singOut_afterMissingUID() async throws {
        @Shared(.uid) var uid = nil
        
        let mapStack = MapNavigationStack.State(root: .init(uploadPost: .init(pickedImage: UIImage())))
        let tab = TabFeature.State(mapStack: mapStack)
        let store: TestStoreOf<RootFeature> = TestStore(initialState: RootFeature.State(destination: .tab(tab))) {
            RootFeature()
        } withDependencies: {
            $0.accountClient.logout = { } // 로그아웃 성공
            $0.continuousClock = ImmediateClock()
            $0.uuid = .incrementing
        }
        
        store.exhaustivity = .off
        
        #expect(store.state.$uid.wrappedValue == nil) // id 저장 사전 검사
        
        await store.send(.view(.viewDidLoad)) // 구독 시작
        await store.send(.destination(.tab(.mapStack(.root(.uploadPost(.presented(.root(.view(.viewDidLoad)))))))))
        await store.receive(\.destination.tab.mapStack.root.uploadPost.presented.root.checkUID)
        await store.receive(\.handleError)
        await store.send(.alert(.presented(.signOut)))
        
        await store.receive(\.signOut) {
            $0.$uid.withLock { $0 = nil }
            $0.destination = .signIn(.init())
        }
    }
    
    @Test func removeUID_afterSignOut() async throws {
        @Shared(.uid) var uid = "uid"
        
        let store: TestStoreOf<RootFeature> = TestStore(initialState: RootFeature.State(destination: .tab(.init()))) {
            RootFeature()
        } withDependencies: {
            $0.accountClient.logout = { } // 로그아웃 성공
            $0.continuousClock = ImmediateClock()
        }
        
        store.exhaustivity = .off
        
        // Shared 저장 확인
        #expect(store.state.destination.tab?.userAccount.$uid.wrappedValue == "uid")
        
        await store.send(.destination(.tab(.userAccount(.view(.logoutButtonTapped)))))
        
        #expect(store.state.destination.tab?.userAccount.$uid.wrappedValue == nil)
    }
    
    @Test func showTabView_whenLoginSucceeded() async throws {
        let store: TestStoreOf<RootFeature> = TestStore(initialState: RootFeature.State(destination: .signIn(.init()))) {
            RootFeature()
        }
        
        await store.send(.destination(.signIn(.delegate(.signInSucceeded)))) {
            $0.destination = .tab(.init())
        }
    }
    
    @Test func showTabView_whenLoggedIn() async throws {
        let store: TestStoreOf<RootFeature> = TestStore(initialState: RootFeature.State(destination: .splash(.init()))) {
            RootFeature()
        } withDependencies: {
            $0.continuousClock = ImmediateClock()
            $0.accountClient.isLoggedIn = { true } // 로그인 상태
            $0.accountClient.refreshIdToken = { } // 토큰 갱신 성공
        }
        
        await store.send(.destination(.splash(.view(.viewDidLoad))))
        await store.receive(\.destination.splash.refreshIdToken)
        await store.receive(\.destination.splash.delegate.showTab)
        await store.receive(\.changeState) {
            $0.destination = .tab(.init())
        }
    }
    
    @Test func showLoginView_whenLoggedOut() async throws {
        let store: TestStoreOf<RootFeature> = TestStore(initialState: RootFeature.State(destination: .splash(.init()))) {
            RootFeature()
        } withDependencies: {
            $0.continuousClock = ImmediateClock()
            $0.accountClient.isLoggedIn = { false }
        }
        
        await store.send(.destination(.splash(.view(.viewDidLoad))))
        await store.receive(\.destination.splash.delegate.showSignIn)
        await store.receive(\.changeState) {
            $0.destination = .signIn(.init())
        }
    }
}
