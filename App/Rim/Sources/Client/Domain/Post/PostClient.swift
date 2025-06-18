//
//  PostClient.swift
//  Rim
//
//  Created by 노우영 on 6/18/25.
//

import Foundation
import Dependencies
import DependenciesMacros
import FirebaseFirestore

@DependencyClient
struct PostClient {
    var post: (_ request: PostRequest) async throws -> Void
}

extension PostClient: DependencyKey {
    static var liveValue: PostClient {
        PostClient { request in
            let firestore = Firestore.firestore(database: "mari-db")
            let data = try Firestore.Encoder().encode(request)
            
            let ref = try await firestore.collection("posts").addDocument(data: data)
        }
    }
}

extension DependencyValues {
    var postClient: PostClient {
        get { self[PostClient.self] }
        set { self[PostClient.self] = newValue }
    }
}



