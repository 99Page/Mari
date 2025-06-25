//
//  NetworkImageLoader.swift
//  Core
//
//  Created by 노우영 on 6/12/25.
//  Copyright © 2025 Page. All rights reserved.
//

import Foundation
import UIKit

public final class NetworkImageLoader: ImageLoader {
    public var next: ImageLoader?
    
    public init() { }

    public func loadImage(fromKey key: String) async throws -> UIImage {
        guard let url = URL(string: key) else {
            throw ImageLoadingError.invalidURL
        }
        
        let (data, _) = try await URLSession.shared.data(from: url)
        
        guard let image = UIImage(data: data) else {
            throw ImageLoadingError.loadFail
        }
        
        return image
    }
}
