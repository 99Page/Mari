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

class RimImageView: UIImageView, Previewable {
    @UIBinding var imageURL: String
    
    init(imageURL: UIBinding<String>) {
        self._imageURL = imageURL
        super.init(frame: .zero)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func configure() {
        makeConstraint()
        updateView()
    }
    
    private func makeConstraint() {
        
    }
    
    func updateView() {
        observe { [weak self] in
            guard let self else { return }
            loadImage()
        }
    }
    
    func loadImage() {
        guard let url = URL(string: imageURL) else { return }
        
        DispatchQueue.global().async {
            if let data = try? Data(contentsOf: url),
               let image = UIImage(data: data) {
                DispatchQueue.main.async {
                    self.image = image
                }
            }
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
