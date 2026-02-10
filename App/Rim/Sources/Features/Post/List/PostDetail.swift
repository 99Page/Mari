//
//  PostDetail.swift
//  Rim
//
//  Created by 노우영 on 2/10/26.
//

import Foundation
import CoreLocation
import Core

struct PostDetail: Identifiable, Equatable, Hashable, SectionProvidable {
    let id: String
    let imageURL: String
    let title: String
    let location: CLLocation
    let creatorID: String
    let description: String
    let section = 0
}
