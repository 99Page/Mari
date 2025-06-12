//
//  MemoryCacheImageLoader.swift
//  Core
//
//  Created by 노우영 on 6/12/25.
//  Copyright © 2025 Page. All rights reserved.
//

import Foundation
import UIKit

final class MemoryCacheImageLoader: ImageLoader {
    var next: ImageLoader?
    private var cache = NSCache<NSString, UIImage>()

    func loadImage(fromKey key: String) async throws -> UIImage {
        let nsKey = key as NSString
        if let result = cache.object(forKey: nsKey) {
            return result
        } else if let result = try? await next?.loadImage(fromKey: key) {
            cache.setObject(result, forKey: nsKey)
            return result
        }
        throw ImageLoadingError.loadFail
    }
}
