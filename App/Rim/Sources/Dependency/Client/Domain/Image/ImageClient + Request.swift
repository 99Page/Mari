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
        
        struct Load {
            let originUrl: String
            let width: Int?
            let height: Int?
        }
    }
}
