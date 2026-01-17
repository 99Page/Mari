//
//  FontLoader.swift
//  Core
//
//  Created by 노우영 on 1/17/26.
//  Copyright © 2026 Page. All rights reserved.
//

import SwiftUI
import CoreText

public struct FontLoader {
    
    // MARK: - Font Lists
    
    // OTF 파일 목록
    private static let otfFontNames = [
        "SpoqaHanSansNeo-Bold",
        "SpoqaHanSansNeo-Light",
        "SpoqaHanSansNeo-Medium",
        "SpoqaHanSansNeo-Regular",
        "SpoqaHanSansNeo-Thin",
    ]
    
    // TTF 파일 목록
    private static let ttfFontNames: [String] = []
    
    // MARK: - Public Method
    
    public static func registerFonts() {
        let bundle = Bundle.module
        
        register(fonts: otfFontNames, extension: "otf", bundle: bundle)
        register(fonts: ttfFontNames, extension: "ttf", bundle: bundle)
    }
    
    // MARK: - Private Helper
    
    private static func register(fonts: [String], extension fileExtension: String, bundle: Bundle) {
        for name in fonts {
            guard let url = bundle.url(forResource: name, withExtension: fileExtension) else {
                // 파일이 없으면 에러 로그 출력 (단, 리스트가 비어있으면 무시)
                if !fonts.isEmpty {
                    print("❌ Core 프레임워크에서 폰트 파일을 찾을 수 없음: \(name).\(fileExtension)")
                }
                continue
            }
            
            var error: Unmanaged<CFError>?
            // 폰트 등록 실행
            CTFontManagerRegisterFontsForURL(url as CFURL, .process, &error)
            
            if let error = error?.takeRetainedValue() {
                let errorDescription = CFErrorCopyDescription(error)
                // 이미 등록된 경우(kCTFontManagerErrorAlreadyRegistered)는 흔한 일이므로 로그 레벨을 낮춤
                print("ℹ️ 폰트 등록 로그 (\(name).\(fileExtension)): \(String(describing: errorDescription))")
            }
        }
    }
}
