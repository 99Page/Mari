//
//  CoordinateDTO.swift
//  Rim
//
//  Created by 노우영 on 9/16/25.
//

import Foundation

struct CoordinateDTO: Decodable {
    let latitude: Double
    let longitude: Double

    private enum CodingKeys: String, CodingKey {
        case latitude = "_latitude"
        case longitude = "_longitude"
    }
}

struct TimestampDTO: Decodable {
    let seconds: Int64
    let nanoseconds: Int32
    enum CodingKeys: String, CodingKey { case seconds = "_seconds", nanoseconds = "_nanoseconds" }
    var date: Date { Date(timeIntervalSince1970: TimeInterval(seconds) + TimeInterval(nanoseconds)/1_000_000_000) }
}
