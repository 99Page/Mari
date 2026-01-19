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

    let myPost = PostDetailDTO(id: "id", title: "title", content: "content", imageUrl: "", markerUrl: "", location: .init(latitude: 0, longitude: 0), creatorID: "creatorID", isMine: true, createdAt: .init(seconds: 0, nanoseconds: 0))
    
    let othersPost = PostDetailDTO(id: "id", title: "title", content: "content", imageUrl: "", markerUrl: "", location: .init(latitude: 0, longitude: 0), creatorID: "creatorID", isMine: false, createdAt: .init(seconds: 0, nanoseconds: 0))
    
    @Test func showMyPostMenus() async throws {
        let store = TestStore(initialState: PostDetailFeature.State(postID: "id")) {
            PostDetailFeature()
        } withDependencies: {
            $0.postClient.fetchPostByID = { _ in
                return  .init(status: "", message: "", result: myPost)
            }
        }
        
        store.exhaustivity = .off
        
        await store.send(.view(.viewDidLoad))
        
        await store.send(.view(.menuButtonTapped)) {
            $0.postMenu = .init(menuOption: .myPost)
        }
    }

    
//   현재 전환 중인 기능으로, 임시 주석 처리
//    @Test func showOtherUsersPostMenus() async throws {
//        let store = TestStore(initialState: PostDetailFeature.State(postID: "id")) {
//            PostDetailFeature()
//        } withDependencies: {
//            $0.postClient.fetchPostByID = { _ in
//                return  .init(status: "", message: "", result: othersPost)
//            }
//        }
//        
//        store.exhaustivity = .off
//        
//        await store.send(.view(.viewDidLoad))
//        
//        await store.send(.view(.menuButtonTapped))
//        await store.send(.postMenu(.presented(.view(.)))))
//    }
}
