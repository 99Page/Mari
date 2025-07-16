//
//  TabTests.swift
//  RimTests
//
//  Created by 노우영 on 7/16/25.
//

import Testing
import ComposableArchitecture
@testable import Rim

@MainActor
struct TabTests {

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
