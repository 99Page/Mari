//
//  AccountNavigationStackTest.swift
//  RimTests
//
//  Created by 노우영 on 7/16/25.
//

import Testing
import ComposableArchitecture
@testable import Rim

@MainActor
struct AccountNavigationStackTest {

    @Test func removesPostFromMyPosts_whenDeletedFromDetailView() async throws {
        let myPosts = MyPostFeature.State(myPosts: [
            .init(id: "post1", title: "title1"),
            .init(id: "post2", title: "title2")
        ])
        
        let detail = PostDetailFeature.State(postID: "post1")
        let path: StackState<AccountNavigationStack.Path.State> = .init([.myPosts(myPosts), .postDetail(detail)])
        let accountStack = AccountNavigationStack.State(path: path, root: .init())
        
        let store = TestStore(initialState: accountStack) {
            AccountNavigationStack()
        } withDependencies: {
            $0.postClient.deletePost = { _ in .init(status: "", message: "", result: .init(id: "post1")) }
        }
        
        store.exhaustivity = .off
        
        await store.send(.path(.element(id: 1, action: .postDetail(.view(.menuButtonTapped)))))
        await store.send(.path(.element(id: 1, action: .postDetail(.postMenu(.presented(.view(.deleteButtonTapped)))))))
        await store.send(.path(.element(id: 1, action: .postDetail(.postMenu(.presented(.alert(.presented(.delete))))))))
        await store.receive(\.path[id: 1].postDetail.postMenu.delegate.deletePost)
        await store.receive(\.path[id: 1].postDetail.delegate.removePostFromMyPosts)
        await store.receive(\.path[id: 0].myPosts.removePostFromList)
        
        #expect(store.state.path[id: 0]?.myPosts?.myPosts[id: "post1"] == nil)
        #expect(store.state.path[id: 0]?.myPosts?.myPosts[id: "post2"] != nil)
    }

}
