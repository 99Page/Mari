//
//  ViewImageGeneator.swift
//  Rim
//
//  Created by 노우영 on 1/14/26.
//

import Foundation
import Dependencies
import DependenciesMacros
import SwiftUI

@DependencyClient
struct ViewImageGenerator {
    // any View를 받아서 UIImage를 반환
    var generate: @MainActor (any View) -> UIImage?
}

extension ViewImageGenerator: DependencyKey {
    static let liveValue = ViewImageGenerator(
        generate: { view in
            let renderer = ImageRenderer(content: AnyView(view))
            
            renderer.scale = UIScreen.main.scale
            renderer.isOpaque = false
            
            return renderer.uiImage
        }
    )
    
    static var previewValue: ViewImageGenerator {
        ViewImageGenerator { _ in
            UIImage(resource: .mustafa)
        }
    }
}

extension DependencyValues {
    var viewImageGenerator: ViewImageGenerator {
        get { self[ViewImageGenerator.self] }
        set { self[ViewImageGenerator.self] = newValue }
    }
}
