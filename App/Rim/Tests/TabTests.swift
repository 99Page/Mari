//
//  TabTests.swift
//  RimTests
//
//  Created by 노우영 on 7/16/25.
//

import Testing
import ComposableArchitecture
@testable import Rim

@Suite("Tab")
struct TabTests {
    @MainActor
    @Suite("Post")
    struct Post {
        @Test func removesPostFromMap_whenDeletedFromMyPosts() async throws {
            let deleteTarget = PostSummaryState(id: "post1", imageURL: "", title: "", coordinate: .init())
            let posts: IdentifiedArrayOf<PostSummaryState> = [
                deleteTarget,
                .init(id: "post2", imageURL: "", title: "", coordinate: .init()),
            ]
            
            let mapStack = MapNavigationStack.State(root: .init(posts: posts))
            
            let userPath: StackState<AccountNavigationStack.Path.State> = .init([.myPosts(.init(posts: posts))])
            let userAccountStack = AccountNavigationStack.State(path: userPath)
            let store = TestStore(initialState: TabFeature.State(mapStack: mapStack, userAccountStack: userAccountStack)) {
                TabFeature()
            } withDependencies: {
                $0.postClient.deletePost = { _ in .init(status: "", message: "", result: .init(id: "post1")) }
            }
            
            store.exhaustivity = .off
            await store.send(.userAccountStack(.path(.element(id: 0, action: .myPosts(.view(.deleteButtonTapped(deleteTarget)))))))
            await store.send(.userAccountStack(.path(.element(id: 0, action: .myPosts(.alert(.presented(.deletePost(deleteTarget))))))))
            await store.receive(\.userAccountStack.path[id: 0].myPosts.delegate.removePostFromMap)
            await store.receive(\.mapStack.root.removePost)
            
            #expect(store.state.mapStack.root.posts[id: "post1"] == nil)
            #expect(store.state.mapStack.root.posts[id: "post2"] != nil)
        }

        @Test func removesPostFromMap_whenDeletedFromPostDetailsInAccountStack() async throws {
            let deleteTarget = PostSummaryState(id: "post1", imageURL: "", title: "", coordinate: .init())
            let posts: IdentifiedArrayOf<PostSummaryState> = [
                deleteTarget,
                .init(id: "post2", imageURL: "", title: "", coordinate: .init()),
            ]
            
            let mapStack = MapNavigationStack.State(root: .init(posts: posts))
            let postDetail = PostDetailFeature.State(postID: "post1")
            
            let userPath: StackState<AccountNavigationStack.Path.State> = .init([.myPosts(.init(posts: posts)), .postDetail(postDetail)])
            let userAccountStack = AccountNavigationStack.State(path: userPath)
            let store = TestStore(initialState: TabFeature.State(mapStack: mapStack, userAccountStack: userAccountStack)) {
                TabFeature()
            } withDependencies: {
                $0.postClient.deletePost = { _ in .init(status: "", message: "", result: .init(id: "post1")) }
            }
            
            store.exhaustivity = .off
            
            await store.send(.userAccountStack(.path(.element(id: 1, action: .postDetail(.view(.trashButtonTapped))))))
            await store.send(.userAccountStack(.path(.element(id: 1, action: .postDetail(.alert(.presented(.deleteButtonTapped)))))))
            await store.receive(\.userAccountStack.path[id: 1].postDetail.delegate.removePostFromMap)
            await store.receive(\.mapStack.root.removePost)
            
            #expect(store.state.mapStack.root.posts[id: "post1"] == nil)
            #expect(store.state.mapStack.root.posts[id: "post2"] != nil)
        }
    }
    
    @MainActor
    @Suite("Token")
    struct Token {
        @Test func refreshIdToken_isTriggeredAfter50Minutes() async throws {
            // 실제 ID 토큰은 키체인에 저장되므로 유닛 테스트에서는 직접 확인할 수 없습니다.
            // 따라서 refreshIdToken이 주기적으로 호출되는지만 확인하기 위해,
            // 이 테스트에서는 refreshIdToken 호출 시 idToken 값을 증가시켜 확인하는 방식으로 mock 처리합니다.
            // - page, 2025.07.16
            var idToken = 0
            let clock = TestClock()
            
            let store = TestStore(initialState: TabFeature.State()) {
                TabFeature()
            } withDependencies: {
                $0.continuousClock = clock
                $0.accountClient.refreshIdToken = { idToken += 1 }
            }
            
            store.exhaustivity = .off
            
            await store.send(.view(.viewDidLoad)) // 타이머 동작 시작
            await clock.advance(by: .seconds(60 * 49)) // 49분까지는 기존 값 유지
            
            #expect(idToken == 0)
            
            await clock.advance(by: .seconds(60 * 1)) // 정확히 50분에 토큰 값 변경
            #expect(idToken == 1)
        }
    }
    
    final class Box<T> {
        var value: T
        init(_ value: T) { self.value = value }
    }
}
