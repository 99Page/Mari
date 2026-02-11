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
        let memoryLoader = MemoryCacheImageLoader()
        let diskLoader = DiskCacheImageLoader()
        let networkLoader = NetworkImageLoader()
        
        memoryLoader.next = diskLoader
        diskLoader.next = networkLoader
        
        let imageFinder = ResizeImageFinder()
        
        return ImageClient { param in
            let imageData: Data?
            
            switch param.format {
            case .jpeg(let quality):
                imageData = param.image.jpegData(compressionQuality: quality)
            case .png:
                imageData = param.image.pngData()
            case .webp(quality: let quality):
                imageData = param.image.webpData(quality: quality)
            }
            
            guard let data = imageData else {
                throw ClientError.unwrappingFailed
            }
            
            let fileExtension = param.format.fileExtension
            let fullPath = "\(param.directoryPath)/\(param.fileName).\(fileExtension)"
            let storageReference = Storage.storage().reference()
            
            // 경로와 확장자 조합 (예: "markers/myMarker.png")
            let imageReference = storageReference.child(fullPath)
            
            let metadata = StorageMetadata()
            metadata.contentType = param.format.contentType
            
            let bucketName = imageReference.bucket
            let path = imageReference.fullPath
            let encodedPath = path.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? path
            
            let _ = try await imageReference.putDataAsync(data, metadata: metadata)
            let url = "https://storage.googleapis.com/\(bucketName)/\(encodedPath)"
            
            return ImageResponse(imageURL: url)
        } loadImage: { request in
            let imageUrl = await imageFinder.findResizedURL(request: request)
            let image = try await memoryLoader.loadImage(fromKey: imageUrl)
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
    
    private static func generateDateUUIDName() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd_HHmmss"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        let dateString = formatter.string(from: Date())
        let shortUUID = UUID().uuidString.prefix(8)
        
        return "\(dateString)_\(shortUUID)"
    }
}

extension DependencyValues {
    var imageClient: ImageClient {
        get { self[ImageClient.self] }
        set { self[ImageClient.self] = newValue }
    }
}


