//
//  PostRequest.swift
//  Rim
//
//  Created by 노우영 on 6/18/25.
//

import Foundation
import FirebaseCore
import CoreLocation
import FirebaseFirestore

struct CreatePostRequest: Encodable {
    let title: String
    let content: String
    let latitude: Double
    let longitude: Double
    let creatorID: String
    let imageUrl: String
}
