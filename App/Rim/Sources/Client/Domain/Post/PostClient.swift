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
    var fetchNearPosts: () async throws -> Void
}

extension PostClient: DependencyKey {
    static var liveValue: PostClient {
        PostClient { request in
            let firestore = Firestore.firestore(database: "mari-db")
            let data = try Firestore.Encoder().encode(request)
            
            let ref = try await firestore.collection("posts").addDocument(data: data)
        } fetchNearPosts: {
            let db = Firestore.firestore(database: "mari-db")

            let snapshot = try await db.collection("posts").getDocuments()
            
            for doc in snapshot.documents {
                debugPrint("title: \(doc.get("title") as? String ?? "")")
                debugPrint("content: \(doc.get("content") as? String ?? "")")
            }
        }
    }
}

extension DependencyValues {
    var postClient: PostClient {
        get { self[PostClient.self] }
        set { self[PostClient.self] = newValue }
    }
}



