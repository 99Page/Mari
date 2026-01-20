//
//  UIImage + memorySize.swift
//  Core
//
//  Created by 노우영 on 1/20/26.
//  Copyright © 2026 Page. All rights reserved.
//

import Foundation
import UIKit

public extension UIImage {
    /// 메모리 점유율 (Bytes 단위)
    var memorySizeInBytes: Int {
        // cgImage가 있으면 정확한 비트맵 크기 계산 가능
        if let cgImage = self.cgImage {
            return cgImage.bytesPerRow * cgImage.height
        }
        // CIImage 기반일 경우 (거의 없지만 방어 코드)
        else if let ciImage = self.ciImage {
            let extent = ciImage.extent
            // RGBA (4bytes) 가정
            return Int(extent.width * extent.height * 4)
        }
        
        return 0
    }
    
    /// 메모리 점유율 (MB 단위, 소수점 2자리 반올림 추천)
    var memorySizeInMB: Double {
        return Double(memorySizeInBytes) / 1024.0 / 1024.0
    }
}
