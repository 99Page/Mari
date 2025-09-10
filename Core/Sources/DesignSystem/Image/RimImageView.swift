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

public class RimImageView: RimView, ConstraintDescribable {
    @UIBinding var imageState: State = .init()
    
    
    public let imageView = UIImageView(frame: .zero)
    public var image: UIBinding<ImageType> = .constant(.custom(url: nil))
    private let placeholder = ImagePlaceholderView()
    
    private var lastLoadedImageURL: String?
    private var imageLoader: ImageLoader
    
    private var observeToken: ObserveToken?
    
    public init() {
        let memoryLoader = MemoryCacheImageLoader()
        let diskLoader = DiskCacheImageLoader()
        let networkLoader = NetworkImageLoader()
        
        memoryLoader.next = diskLoader
        diskLoader.next = networkLoader
        
        self.imageLoader = memoryLoader
        super.init(state: .constant(.init()))
        makeConstraint()
        updateView()
    }
    
    public init(_ name: String, configure: ((RimImageView) -> Void)? = nil) {
        let memoryLoader = MemoryCacheImageLoader()
        let diskLoader = DiskCacheImageLoader()
        let networkLoader = NetworkImageLoader()
        
        memoryLoader.next = diskLoader
        diskLoader.next = networkLoader
        
        self.imageLoader = memoryLoader
        super.init(state: .constant(.init()))
    }
    
    public init(state: UIBinding<State>) {
        self._imageState = state
        
        let memoryLoader = MemoryCacheImageLoader()
        let diskLoader = DiskCacheImageLoader()
        let networkLoader = NetworkImageLoader()
        
        memoryLoader.next = diskLoader
        diskLoader.next = networkLoader
        
        self.imageLoader = memoryLoader
        
        super.init(state: state.apperance)
        
        makeConstraint()
        updateView()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
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
    
    public func updateView() {
        observeToken?.cancel()
        
        observeToken = observe { [weak self] in
            guard let self else { return }
            resetAppearances()
            imageView.contentMode = .scaleAspectFill
            imageView.clipsToBounds = true
            updateImage()
        }
    }
    
    private func resetAppearances() {
        self.imageView.tintColor = .systemBlue
    }
    
    private func updateImage() {
        switch image.wrappedValue {
        case let .resource(resource):
            self.imageView.image = UIImage(resource: resource)
            self.placeholder.isHidden = true
        case .custom(let url):
            loadImage(from: url)
        case let .symbol(name, color):
            self.imageView.image = UIImage(systemName: name)
            self.imageView.tintColor = color
            self.placeholder.isHidden = true
        case let .uiImage(uiImage):
            self.imageView.image = uiImage
            self.placeholder.isHidden = true
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
    
    
    public enum ImageType: Equatable {
        case resource(imageResource: ImageResource)
        case custom(url: String?)
        case symbol(name: String, fgColor: UIColor)
        case uiImage(uiImage: UIImage)
    }
    
    public struct State: Equatable {
        public var apperance: RimView.State
        
        public init(appearance: RimView.State = .init()) {
            self.apperance = appearance
        }
    }
}
