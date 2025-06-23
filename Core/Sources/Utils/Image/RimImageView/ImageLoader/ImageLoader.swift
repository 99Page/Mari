//
//  ImageLoader.swift
//  Core
//
//  Created by 노우영 on 6/12/25.
//  Copyright © 2025 Page. All rights reserved.
//

import Foundation
import UIKit

public protocol ImageLoader: AnyObject {
    var next: ImageLoader? { get set }
    func loadImage(fromKey key: String) async throws -> UIImage
}

enum ImageLoadingError: Error {
    case invalidURL
    case loadFail
}

