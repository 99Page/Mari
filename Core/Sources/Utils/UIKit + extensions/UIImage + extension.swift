//
//  UIImage + memorySize.swift
//  Core
//
//  Created by 노우영 on 1/20/26.
//  Copyright © 2026 Page. All rights reserved.
//

import Foundation
import UIKit
import UniformTypeIdentifiers

public extension UIImage {
    var memorySizeInBytes: Int {
        if let cgImage = self.cgImage {
            return cgImage.bytesPerRow * cgImage.height
        }
        
        else if let ciImage = self.ciImage {
            let extent = ciImage.extent
            return Int(extent.width * extent.height * 4) // RGBA (4bytes) 가정
        }
        
        return 0
    }
    
    var memorySizeInMB: Double {
        return Double(memorySizeInBytes) / 1024.0 / 1024.0
    }
    
    func fixedOrientation() -> UIImage {
        if imageOrientation == .up { return self }
        
        UIGraphicsBeginImageContextWithOptions(size, false, scale)
        draw(in: CGRect(origin: .zero, size: size))
        let normalizedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return normalizedImage ?? self
    }
    
    func cropVerticalCenter(aspectRatio: CGFloat) -> UIImage {
        let image = self.fixedOrientation()
        
        let originalWidth = image.size.width
        let originalHeight = image.size.height
        
        let newWidth = originalWidth
        
        let newHeight = floor(originalWidth * aspectRatio)
        let yOffset = floor((originalHeight - newHeight) / 2.0)
        
        let cropRect = CGRect(x: 0, y: yOffset, width: newWidth, height: newHeight)
        
        guard let cgImage = image.cgImage?.cropping(to: cropRect) else {
            return image
        }
        
        return UIImage(cgImage: cgImage, scale: image.scale, orientation: .up)
    }
    
    func resize(toWidth targetWidth: CGFloat) -> UIImage {
        let currentSize = self.size
        
        if currentSize.width <= targetWidth { return self }
        
        let widthRatio = targetWidth / currentSize.width
        let newHeight = currentSize.height * widthRatio
        
        let newSize = CGSize(width: targetWidth, height: newHeight)
        let rect = CGRect(origin: .zero, size: newSize)
        
        UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
        self.draw(in: rect)
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return newImage ?? self
    }
    
    /// 이미지를 WebP 데이터로 변환합니다.
    /// - Parameter quality: 압축 품질 (0.0 ~ 1.0). 보통 0.8 추천.
    func webpData(quality: CGFloat) -> Data? {
        let data = NSMutableData()
        
        guard let destination = CGImageDestinationCreateWithData(
            data, UTType.webP.identifier as CFString, 1, nil
        ) else { return nil }
        
        let options: [CFString: Any] = [
            kCGImageDestinationLossyCompressionQuality: quality
        ]
        
        guard let cgImage = self.cgImage ?? self.ciImage?.convertToCGImage() else {
            return nil
        }
        
        CGImageDestinationAddImage(destination, cgImage, options as CFDictionary)
        guard CGImageDestinationFinalize(destination) else { return nil }
        
        return data as Data
    }
}

private extension CIImage {
    func convertToCGImage() -> CGImage? {
        let context = CIContext(options: nil)
        return context.createCGImage(self, from: self.extent)
    }
}
