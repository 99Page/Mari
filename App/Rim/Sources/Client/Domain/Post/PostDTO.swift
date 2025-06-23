//
//  PostDTO.swift
//  Rim
//
//  Created by 노우영 on 6/23/25.
//

import Foundation

struct PostDTO: Decodable {
    let id: String
    let title: String
    let content: String
}
