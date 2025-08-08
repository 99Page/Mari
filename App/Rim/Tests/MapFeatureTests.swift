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
import NMapsMap
@testable import Rim

@MainActor
struct MapFeatureTests {
    @Test
    func refreshPosts_whenLatestFilterSelected() async throws {
        @Shared(.uid) var uid = "uid"
        
        let uploadPostStack = UploadPostNavigationStack.State(pickedImage: UIImage(), photoLocation: NMGLatLng(lat: 0, lng: 0))
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
        await store.receive(\.uploadPost.presented.root.delegate)
        await store.receive(\.fetchPosts)
        await store.receive(\.setPosts)
        
        #expect(store.state.posts.isEmpty == false)
    }
    
    @Test
    func doesNotRefreshPosts_whenPopularFilterSelected() async throws {
        @Shared(.uid) var uid = "uid"
        
        let uploadPostStack = UploadPostNavigationStack.State(pickedImage: UIImage(), photoLocation: NMGLatLng(lat: 0, lng: 0) )
        let mapState = MapFeature.State(uploadPost: uploadPostStack, selectedFilter: .popular)
        
        let store = TestStore(initialState: mapState) {
            MapFeature()
        } withDependencies: {
            $0.uuid = .incrementing
            $0.continuousClock = ImmediateClock()
        }
        
        store.exhaustivity = .off
        #expect(store.state.posts.isEmpty) // 초기값 확인
        
        await store.send(.uploadPost(.presented(.root(.view(.viewDidLoad))))) // 이미지 업로드 처리
        await store.receive(\.uploadPost.presented.root.checkUID)
        await store.receive(\.uploadPost.presented.root.uploadImage) 
        
        await store.receive(\.uploadPost.presented.root.setImageURL) {
            $0.uploadPost?.root.imageURL = "https://picsum.photos/200/300"
        }
        
        await store.send(.uploadPost(.presented(.root(.view(.binding(.set(\.title.text, "title"))))))) {
            $0.uploadPost?.root.title.text = "title"
        }
        
        await store.send(.uploadPost(.presented(.root(.view(.uploadButtonTapped)))))
        await store.receive(\.uploadPost.presented.root.uploadPost)
        await store.receive(\.uploadPost.presented.root.dismissProgress)
        await store.receive(\.uploadPost.presented.root.delegate)
        
        #expect(store.state.posts.isEmpty)
    }
}
