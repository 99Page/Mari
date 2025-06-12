//
//  RimImageView.swift
//  Core
//
//  Created by 노우영 on 6/11/25.
//  Copyright © 2025 Page. All rights reserved.
//

import Foundation
import UIKit
import SnapKit
import ComposableArchitecture
import SwiftUI

public class RimImageView: UIImageView, Previewable {
    
    @UIBinding var imageURL: String
    
    private var lastLoadedImageURL: String?
    
    private var imageLoader: ImageLoader
    
    public init(imageURL: UIBinding<String>) {
        self._imageURL = imageURL
        
        let memoryLoader = MemoryCacheImageLoader()
        let diskLoader = DiskCacheImageLoader()
        let networkLoader = NetworkImageLoader()
        
        memoryLoader.next = diskLoader
        diskLoader.next = networkLoader
        
        self.imageLoader = memoryLoader
        
        super.init(frame: .zero)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public func configure() {
        updateView()
    }
    
    private func updateView() {
        observe { [weak self] in
            guard let self else { return }
            loadImage()
        }
    }
    
    private func loadImage() {
        guard imageURL != lastLoadedImageURL else { return }
        
        do {
            Task {
                let loadedImage = try await imageLoader.loadImage(fromKey: imageURL)
                self.image = loadedImage
                lastLoadedImageURL = imageURL
            }
        } catch {
            
        }
    }
}

@available(iOS 17.0, *)
#Preview {
    @Previewable @UIBinding var imageURL = "https://picsum.photos/200/300"
    
    ViewPreview(fromY: \.centerY, toY: \.centerY) {
        RimImageView(imageURL: $imageURL)
    }
}
