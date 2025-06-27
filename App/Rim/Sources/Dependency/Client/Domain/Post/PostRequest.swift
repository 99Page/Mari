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

struct PostRequest: Encodable {
    let content: String
    let createdAt = Timestamp(date: .now)
    let creatorID: String
    let dailyScore = 0
    let imageUrl: String
    let location: GeoPoint
    let monthlyScore = 0
    let title: String
    let viewCount = 0
    let weeklyScore = 0
}
