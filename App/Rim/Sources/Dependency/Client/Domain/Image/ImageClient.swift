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
    var uploadImage: (_ request: Request.Upload) async throws -> ImageResponse
    var loadImage: (_ request: Request.Load) async throws -> UIImage
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
        } loadImage: { request in
            let memoryLoader = MemoryCacheImageLoader()
            let diskLoader = DiskCacheImageLoader()
            let networkLoader = NetworkImageLoader()
            
            memoryLoader.next = diskLoader
            diskLoader.next = networkLoader
            
            let imageFinder = ResizeImageFinder()
            let imageUrl = await imageFinder.findResizedURL(request: request)
            let image = try await memoryLoader.loadImage(fromKey: request.originUrl)
            return image
        }
    }
    
    static var previewValue: ImageClient {
        ImageClient { _ in
            return .init(imageURL: "https://picsum.photos/200/300")
        } loadImage: { _ in
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


