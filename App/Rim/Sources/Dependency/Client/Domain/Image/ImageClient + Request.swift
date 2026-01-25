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
            let path: String
            let fileName: String
            let format: ImageUploadFormat
            
            enum ImageUploadFormat {
                case jpeg(quality: CGFloat)
                case png
                
                var contentType: String {
                    switch self {
                    case .jpeg: return "image/jpeg"
                    case .png: return "image/png"
                    }
                }
                
                var fileExtension: String {
                    switch self {
                    case .jpeg: return "jpg"
                    case .png: return "png"
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
            
            var width: Int? {
                switch self {
                case .original: nil
                case .small: 240
                case .large: 1080
                }
            }
            
            var height: Int? {
                switch self {
                case .original: nil
                case .small: 240
                case .large: 1080
                }
            }
        }
    }
}
