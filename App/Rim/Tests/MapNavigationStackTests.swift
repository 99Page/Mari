//
//  MapNavigationStackTetst.swift
//  RimTests
//
//  Created by 노우영 on 7/16/25.
//

import Testing
import ComposableArchitecture
@testable import Rim

@MainActor
struct MapNavigationStackTests {

    @Test func removesPostFromMap_whenDeletedInDetailView() async throws {
        let path: StackState<MapNavigationStack.Path.State> = .init([.postDetail(.init(postID: "post1"))])
        let root = MapFeature.State(posts: [
            .init(id: "post1", imageURL: "image", title: "title", coordinate: .init()),
            .init(id: "post2", imageURL: "image", title: "title", coordinate: .init()),
        ]
        )
        let mapStack = MapNavigationStack.State(path: path, root: root)
        
        let store = TestStore(initialState: mapStack) {
            MapNavigationStack()
        } withDependencies: {
            // postDetail과 동일한 아이디 사용
            $0.postClient.fetchPostByID = { _ in .init(id: "post1", title: "title", content: "content", imageUrl: "", location: .init(latitude: 0, longitude: 0), isMine: true)}
            $0.postClient.deletePost = { _ in .init(status: "", message: "", result: .init(id: "post1"))}
        }
        
        store.exhaustivity = .off
        
        await store.send(.path(.element(id: 0, action: .postDetail(.view(.trashButtonTapped)))))
        await store.send(.path(.element(id: 0, action: .postDetail(.alert(.presented(.deleteButtonTapped))))))
        await store.receive(\.path[id: 0].postDetail.delegate.removePostFromMap)
        
        #expect(store.state.root.posts[id: "post1"] == nil)
        #expect(store.state.root.posts[id: "post2"] != nil)
    }

}
