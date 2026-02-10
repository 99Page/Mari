//
//  ImageURL.swift
//  Core
//
//  Created by 노우영 on 2/10/26.
//  Copyright © 2026 Page. All rights reserved.
//

import Foundation

public struct MockImage: Identifiable, Equatable, Hashable {
    public let id: UUID
    public let seed: Int     // Picsum의 고유 시드 (이 값이 같으면 항상 같은 이미지가 옴)
    public let width: Int
    public let height: Int
    
    public var url: URL? {
        return URL(string: "https://picsum.photos/seed/\(seed)/\(width)/\(height)")
    }
    
    public  var urlString: String {
        return url?.absoluteString ?? ""
    }
    
    public init(id: UUID = UUID(), seed: Int = Int.random(in: 1...99999), width: Int, height: Int) {
        self.id = id
        self.seed = seed
        self.width = width
        self.height = height
    }
}

// MARK: - Mock Helpers (인스타 비율 지원)
public extension MockImage {
    
    /// 1:1 정방형 (Square)
    static func square(size: Int = 1000) -> Self {
        return MockImage(width: size, height: size)
    }
    
    /// 4:5 세로형 (Portrait) - 인스타 최대 비율
    static func portrait(width: Int = 1000) -> Self {
        return MockImage(width: width, height: Int(Double(width) * 1.25))
    }
    
    /// 1.91:1 가로형 (Landscape)
    static func landscape(width: Int = 1000) -> Self {
        return MockImage(width: width, height: Int(Double(width) / 1.91))
    }
    
    /// 9:16 스토리형 (Story) - 피드에서는 잘림
    static func story(width: Int = 1000) -> Self {
        return MockImage(width: width, height: Int(Double(width) * 1.77))
    }
    
    /// 완전 랜덤 비율
    static func random() -> Self {
        let w = Int.random(in: 500...1000)
        let h = Int.random(in: 500...1200)
        return MockImage(width: w, height: h)
    }
}
