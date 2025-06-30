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

    private let fileManager = FileManager.default
    private let cacheDirectory: URL = {
        let url = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        return url.appendingPathComponent("ImageDiskCache", isDirectory: true)
    }()

    init() {
        try? fileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
    }

    func loadImage(fromKey key: String) async throws -> UIImage {
        let filename = key.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed) ?? UUID().uuidString
        let fileURL = cacheDirectory.appendingPathComponent(filename)

        if let data = try? Data(contentsOf: fileURL),
           let image = UIImage(data: data) {
            return image
        }

        guard let result = try? await next?.loadImage(fromKey: key),
              let imageData = result.pngData() else {
            throw ImageLoadingError.loadFail
        }

        try? imageData.write(to: fileURL)
        return result
    }
}
