//
//  UIButton + design.swift
//  Mari
//
//  Created by 노우영 on 5/26/25.
//

import Foundation
import UIKit

import UIKit

extension UIButton {
    func design(_ style: ButtonStyle) {
        self.setImage(style.image, for: .normal)
        self.tintColor = style.tintColor
        self.backgroundColor = style.backgroundColor
    }
}

struct ButtonStyle {
    let image: UIImage
    let size: CGFloat
    let tintColor: UIColor
    let backgroundColor: UIColor
}
