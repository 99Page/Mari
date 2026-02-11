//
//  ImageClient + Request.swift
//  Rim
//
//  Created by 노우영 on 1/24/26.
//

import Foundation
import UIKit

extension ImageClient {
    enum Request {
        
        // MARK: - Upload Request
        struct Upload {
            let image: UIImage
            let directoryPath: String
            let fileName: String
            let format: ImageUploadFormat
            
            enum ImageUploadFormat {
                case jpeg(quality: CGFloat)
                case png
                case webp(quality: CGFloat)
                
                var contentType: String {
                    switch self {
                    case .jpeg: return "image/jpeg"
                    case .png: return "image/png"
                    case .webp: return "image/webp"
                    }
                }
                
                var fileExtension: String {
                    switch self {
                    case .jpeg: return "jpg"
                    case .png: return "png"
                    case .webp: return "webp"
                    }
                }
            }
        }
        
        // MARK: - Load Request
        struct Load {
            let originalUrl: String
            let size: ImageSize // 👈 Int? 대신 Enum 사용
        }
        
        enum ImageSize {
            case original
            case small
            case large
            
            private var aspectRatio: Double { 1.25 }
            
            var width: Int? {
                switch self {
                case .original: return nil
                case .small: return 240
                case .large: return 540
                }
            }
            
            var height: Int? {
                switch self {
                case .original: return nil
                case .small:
                    return Int(Double(240) * aspectRatio)
                case .large:
                    return Int(Double(1080) * aspectRatio)
                }
            }
            
            var size: CGSize? {
                guard let w = width, let h = height else { return nil }
                return CGSize(width: w, height: h)
            }
        }
    }
}
