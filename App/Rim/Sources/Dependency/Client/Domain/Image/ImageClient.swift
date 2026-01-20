//
//  ImageClient.swift
//  Rim
//
//  Created by 노우영 on 6/18/25.
//

import Foundation
import Dependencies
import DependenciesMacros
import UIKit
import FirebaseStorage
import Core

@DependencyClient
struct ImageClient {
    var uploadImage: (_ param: UploadImageParameter) async throws -> ImageResponse
    var loadImage: (_ url: String, _ size: CGSize) async throws -> UIImage
    
    struct UploadImageParameter {
        let image: UIImage
        let path: String
        let fileName: String
        let format: ImageUploadFormat
    }
    
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

extension ImageClient: DependencyKey {
    static var liveValue: ImageClient {
        ImageClient { param in
            // 지정된 fileName 경로에 이미지를 Firebase Storage에 저장합니다.
            let imageData: Data?
            
            switch param.format {
            case .jpeg(let quality):
                imageData = param.image.jpegData(compressionQuality: quality)
            case .png:
                imageData = param.image.pngData()
            }
            
            guard let data = imageData else {
                throw ClientError.unwrappingFailed
            }
            
            let storageReference = Storage.storage().reference()
            
            // 경로와 확장자 조합 (예: "markers/myMarker.png")
            let fullFileName = "\(param.fileName).\(param.format.fileExtension)"
            let imageReference = storageReference.child("\(param.path)/\(fullFileName)")
            
            let metadata = StorageMetadata()
            metadata.contentType = param.format.contentType
            
            let _ = try await imageReference.putDataAsync(data, metadata: metadata)
            let url = try await imageReference.downloadURL()
            
            return ImageResponse(imageURL: url.absoluteString)
        } loadImage: { url, size in
            let memoryLoader = MemoryCacheImageLoader()
            let diskLoader = DiskCacheImageLoader()
            let networkLoader = NetworkImageLoader()
            
            memoryLoader.next = diskLoader
            diskLoader.next = networkLoader
            
            let image = try await memoryLoader.loadImage(fromKey: url)
            let renderer = UIGraphicsImageRenderer(size: size)
            
            return renderer.image { _ in
                image.draw(in: CGRect(origin: .zero, size: size))
            }
        }
    }
    
    static var previewValue: ImageClient {
        ImageClient { _ in
            return .init(imageURL: "https://picsum.photos/200/300")
        } loadImage: { _, _ in
            return UIImage(resource: .rimLogo)
        }

    }
    
    static var testValue: ImageClient {
        previewValue
    }
}

extension DependencyValues {
    var imageClient: ImageClient {
        get { self[ImageClient.self] }
        set { self[ImageClient.self] = newValue }
    }
}


