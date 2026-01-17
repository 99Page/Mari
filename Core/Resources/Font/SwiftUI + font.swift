//
//  SwiftUI + font.swift
//  Core
//
//  Created by 노우영 on 1/17/26.
//  Copyright © 2026 Page. All rights reserved.
//

import SwiftUI

public extension View {
    /// Spoqa 폰트를 적용합니다. (기존 .font()와 이름은 같지만 파라미터로 구분됨)
    /// - Parameters:
    ///   - size: 폰트 크기
    ///   - weight: 폰트 굵기 (기본값: .regular)
    func font(size: CGFloat, font: CoreFont) -> some View {
        self.font(.custom(font.name, size: size))
    }
}
