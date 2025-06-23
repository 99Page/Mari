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
import FirebaseFunctions

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
            let urlString = "https://us-central1-mari-4baca.cloudfunctions.net/getPosts"
            guard let url = URL(string: urlString) else {
                throw URLError(.badURL)
            }
            
            let (data, response) = try await URLSession.shared.data(from: url)

            if let httpResponse = response as? HTTPURLResponse {
                print("📡 Status Code: \(httpResponse.statusCode)")
            }
            print("🔍 Response String: \(String(data: data, encoding: .utf8) ?? "nil")")

            do {
                // Replace this with your actual model type
                // let posts = try JSONDecoder().decode([Post].self, from: data)
                // 여기서 posts를 상태에 전달하거나 반환하는 로직이 필요하다면 추가
                // print("✅ Posts fetched: \(posts)")
            } catch {
                debugPrint("error: \(error)")
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



