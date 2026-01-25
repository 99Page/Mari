//
//  Triangle.swift
//  Core
//
//  Created by 노우영 on 1/14/26.
//  Copyright © 2026 Page. All rights reserved.
//

import SwiftUI

public struct Triangle: Shape {
    
    public init() { }
    
    public func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.maxY))      // 아래쪽 꼭지점
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY))   // 왼쪽 위
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))   // 오른쪽 위
        path.closeSubpath()
        return path
    }
}

#Preview {
    Triangle()
}
