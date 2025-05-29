//
//  UIButon + design.swift
//  Core
//
//  Created by 노우영 on 5/29/25.
//  Copyright © 2025 Page. All rights reserved.
//

import UIKit
import SwiftUI

public extension UIButton {
    func design(_ style: ButtonStyle) {
        self.setImage(style.image, for: .normal)
        self.tintColor = style.tintColor
        self.backgroundColor = style.backgroundColor
    }
}

public struct ButtonStyle {
    public let image: UIImage
    public let size: CGFloat
    public let tintColor: UIColor
    public let backgroundColor: UIColor
    
    public init(image: UIImage, size: CGFloat, tintColor: UIColor, backgroundColor: UIColor) {
        self.image = image
        self.size = size
        self.tintColor = tintColor
        self.backgroundColor = backgroundColor
    }
}

private class CustomButton: UIButton, Previewable {
    func configure() {
        let style = ButtonStyle(
            image: UIImage(systemName: "pencil")!,
            size: 44,
            tintColor: .blue,
            backgroundColor: .clear
        )
        
        self.design(style)
        
        
    }
}

#Preview {
    ViewPreview(fromY: \.centerY, toY: \.centerY) {
        CustomButton()
    }
}
