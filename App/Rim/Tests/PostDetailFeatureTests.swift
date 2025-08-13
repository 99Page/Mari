//
//  PostDetailFeatureTests.swift
//  RimTests
//
//  Created by 노우영 on 8/8/25.
//

import ComposableArchitecture
import Testing
@testable import Rim

@MainActor
struct PostDetailFeatureTests {

    @Test func showMyPostMenus() async throws {
        let store = TestStore(initialState: PostDetailFeature.State(postID: "id")) {
            PostDetailFeature()
        } withDependencies: {
            $0.postClient.fetchPostByID = { _ in
                let dto = PostDetailDTO(id: "id", title: "title", content: "content", imageUrl: "", location: .init(latitude: 0, longitude: 0), creatorID: "creatorID", isMine: true)
                return  .init(status: "", message: "", result: dto)
            }
        }
        
        store.exhaustivity = .off
        
        await store.send(.view(.viewDidLoad))
        
        await store.send(.view(.menuButtonTapped)) {
            $0.postMenu = .init(activeMenus: [.delete])
        }
    }

    @Test func showOtherUsersPostMenus() async throws {
        let store = TestStore(initialState: PostDetailFeature.State(postID: "id")) {
            PostDetailFeature()
        } withDependencies: {
            $0.postClient.fetchPostByID = { _ in
                let dto = PostDetailDTO(id: "id", title: "title", content: "content", imageUrl: "", location: .init(latitude: 0, longitude: 0), creatorID: "creatorID", isMine: false)
                return  .init(status: "", message: "", result: dto)
            }
        }
        
        store.exhaustivity = .off
        
        await store.send(.view(.viewDidLoad))
        
        await store.send(.view(.menuButtonTapped)) {
            $0.postMenu = .init(activeMenus: [.block, .report])
        }
    }
}
