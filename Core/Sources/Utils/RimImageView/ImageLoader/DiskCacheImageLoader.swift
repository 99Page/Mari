//
//  DiskCacheImageLoader.swift
//  Core
//
//  Created by 노우영 on 6/12/25.
//  Copyright © 2025 Page. All rights reserved.
//

import Foundation
import UIKit

final class DiskCacheImageLoader: ImageLoader {
    var next: ImageLoader?

    func loadImage(fromKey key: String) async throws -> UIImage {
        // Placeholder: bypass disk and forward to next
        guard let result = try? await next?.loadImage(fromKey: key) else {
            throw ImageLoadingError.loadFail
        }
        return result
    }
}
