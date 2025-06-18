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
import SwiftNavigation
import SwiftUI

public class RimImageView: UIView, Previewable {
    
    @UIBinding var imageURL: String
    
    private let imageView = UIImageView(frame: .zero)
    private let placeholder = ImagePlaceholderView()
    
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
        makeConstraint()
        updateView()
        
        placeholder.configure()
    }
    
    private func makeConstraint() {
        self.addSubview(imageView)
        self.addSubview(placeholder)
        
        imageView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        placeholder.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
    
    private func updateView() {
        observe { [weak self] in
            guard let self else { return }
            loadImage()
        }
    }
    
    private func loadImage() {
        guard imageURL != lastLoadedImageURL else { return }
        
        placeholder.isHidden = false
        
        Task {
            do {
                let loadedImage = try await imageLoader.loadImage(fromKey: imageURL)
                self.imageView.image = loadedImage
                self.placeholder.isHidden = true
                lastLoadedImageURL = imageURL
            } catch {
                self.imageView.image = UIImage(systemName: "photo")
                self.placeholder.isHidden = true
            }
        }
    }
}

@available(iOS 17.0, *)
#Preview {
    @Previewable @UIBinding var url = ""
    
    ViewPreview(fromY: \.centerY, toY: \.centerY) {
        RimImageView(imageURL: $url)
    }
}
