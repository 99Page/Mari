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
    
    @UIBinding var state: State
    
    public let imageView = UIImageView(frame: .zero)
    private let placeholder = ImagePlaceholderView()
    
    private var lastLoadedImageURL: String?
    private var imageLoader: ImageLoader
    
    public init(state: UIBinding<State>) {
        self._state = state
        
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
            imageView.contentMode = .scaleAspectFill
            imageView.clipsToBounds = true
            updateImage()
        }
    }
    
    private func updateImage() {
        switch state.image {
        case .resource:
            break
        case .custom(let url):
            loadImage(from: url)
        case .symbol:
            break
        }
    }
    
    private func loadImage(from url: String?) {
        guard let url = url else { return }
        guard url != lastLoadedImageURL else { return }
        
        placeholder.isHidden = false
        
        Task {
            do {
                let loadedImage = try await imageLoader.loadImage(fromKey: url)
                self.imageView.image = loadedImage
                self.placeholder.isHidden = true
                lastLoadedImageURL = url
            } catch {
                self.imageView.image = UIImage(systemName: "photo")
                self.placeholder.isHidden = true
            }
        }
    }
    
    public struct State: Equatable {
        public var image: ImageType
        
        public init(image: ImageType) {
            self.image = image
        }
        
        public enum ImageType: Equatable {
            case resource(name: String)
            case custom(url: String?)
            case symbol(name: String)
        }
        
        public static func == (lhs: RimImageView.State, rhs: RimImageView.State) -> Bool {
            return lhs.image == rhs.image
        }
    }
}

@available(iOS 17.0, *)
#Preview {
    @Previewable @UIBinding var state: RimImageView.State = .init(image: .custom(url: "https://picsum.photos/200/300"))
    
    ViewPreview(fromY: \.centerY, toY: \.centerY) {
        RimImageView(state: $state)
    }
}
