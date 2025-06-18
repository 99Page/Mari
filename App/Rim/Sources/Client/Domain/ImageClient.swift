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

@DependencyClient
struct ImageClient {
    var uploadImage : (_ image: UIImage, _ fileName: String) async throws -> ImageResponse
}

extension ImageClient: DependencyKey {
    static var liveValue: ImageClient {
        ImageClient { image, fileName in
            guard let imageData = image.jpegData(compressionQuality: 0.8) else {
                throw ClientError.unwrappingFailed
            }
            
            let storageReference = Storage.storage().reference()
            let imageName = fileName + ".jpg"
            let imageReference = storageReference.child("images/\(imageName)")
            
            let metadata = StorageMetadata()
            metadata.contentType = "image/jpeg"
            
            let _ = try await imageReference.putDataAsync(imageData)
            let url = try await imageReference.downloadURL()
            
            return ImageResponse(imageURL: url.absoluteString)
        }
    }
}

extension DependencyValues {
    var imageClient: ImageClient {
        get { self[ImageClient.self] }
        set { self[ImageClient.self] = newValue }
    }
}


