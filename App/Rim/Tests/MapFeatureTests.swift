//
//  MapFeatureTests.swift
//  RimTests
//
//  Created by 노우영 on 7/14/25.
//

import Foundation
import ComposableArchitecture
import Testing
import UIKit
@testable import Rim

@MainActor
struct MapFeatureTests {
    @Test
    func refreshPosts_afterCreatePost() async throws {
        @Shared(.uid) var uid = "uid"
        
        let uploadPostStack = UploadPostNavigationStack.State(pickedImage: UIImage())
        let mapState = MapFeature.State(uploadPost: uploadPostStack, selectedFilter: .latest)
        
        let store = TestStore(initialState: mapState) {
            MapFeature()
        } withDependencies: {
            $0.uuid = .incrementing
            $0.continuousClock = ImmediateClock()
        }
        
        store.exhaustivity = .off
        
        #expect(store.state.posts.isEmpty) // 초기값 확인
        
        await store.send(.uploadPost(.presented(.root(.view(.viewDidLoad))))) // 이미지 업로드 처리
        await store.send(.uploadPost(.presented(.root(.view(.binding(.set(\.title.text, "title")))))))
        
        await store.send(.uploadPost(.presented(.root(.view(.uploadButtonTapped)))))
        await store.receive(\.uploadPost.presented.root.delegate.uploadSucceeded)
        await store.receive(\.fetchPosts)
        await store.receive(\.setPosts)
        
        #expect($0.posts.isEmpty == false)
    }
    
    @Test
    func refreshPosts_afterCreatePost2() async throws {
        @Shared(.uid) var uid = "uid"
        
        let uploadPostStack = UploadPostNavigationStack.State(pickedImage: UIImage())
        let mapState = MapFeature.State(uploadPost: uploadPostStack, selectedFilter: .popular)
        
        let store = TestStore(initialState: mapState) {
            MapFeature()
        } withDependencies: {
            $0.uuid = .incrementing
            $0.continuousClock = ImmediateClock()
        }
        
        #expect(store.state.posts.isEmpty) // 초기값 확인
        
        await store.send(.uploadPost(.presented(.root(.view(.viewDidLoad))))) // 이미지 업로드 처리
        await store.send(.uploadPost(.presented(.root(.view(.binding(.set(\.title.text, "title")))))))
        
        await store.send(.uploadPost(.presented(.root(.view(.uploadButtonTapped)))))
        await store.receive(\.uploadPost.presented.root.delegate.uploadSucceeded)
    }
}
