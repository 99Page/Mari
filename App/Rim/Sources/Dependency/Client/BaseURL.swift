//
//  BaseURL.swift
//  Rim
//
//  Created by 노우영 on 6/23/25.
//

import Foundation

let functionsURL: String = {
    guard let urlString = Bundle.main.infoDictionary?["BASE_URL"] as? String else {
        assertionFailure("BASE_URL not set in Info.plist")
        return ""
    }
    
    return urlString
}()
