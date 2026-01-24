//
//  ResizeImageFinder.swift
//  Rim
//
//  Created by 노우영 on 1/24/26.
//

import Foundation
import FirebaseStorage
import Core

struct ResizeImageFinder {
    
    /// 원본 이미지의 URL을 기반으로 썸네일 URL(String)을 찾습니다.
    /// 실패하면 원본 URL String을 그대로 반환합니다.
    /// - Returns: 썸네일 URL 문자열 (없으면 원본 문자열)
    func findResizedURL(request: ImageClient.Request.Load) async -> String {
        
        guard let width = request.size.width, let height = request.size.height else {
            return request.originalUrl
        }
        
        let storage = Storage.storage()
        
        let originalRef = storage.reference(forURL: request.originalUrl)
        
        let originalName = originalRef.name
        let components = originalName.split(separator: ".")
        
        guard components.count > 1, let fileExtension = components.last else {
            return request.originalUrl
        }
        
        let fileNameWithoutExtension = components.dropLast().joined(separator: ".")
        
        let resizedFileName = "\(fileNameWithoutExtension)_\(width)x\(height).\(fileExtension)"
        
        let resizedRef: StorageReference
        
        if let parentRef = originalRef.parent() {
            resizedRef = parentRef.child(resizedFileName)
        } else {
            resizedRef = storage.reference().child(resizedFileName)
        }
        
        do {
            let url = try await resizedRef.downloadURL()
            return url.absoluteString
        } catch {
            return request.originalUrl
        }
    }
}
