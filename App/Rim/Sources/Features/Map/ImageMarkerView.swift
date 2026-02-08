//
//  ImageMarkerView.swift
//  Rim
//
//  Created by 노우영 on 1/14/26.
//

import SwiftUI
import Core

struct ImageMarkerView: View {
    var image: Image
    var title: String
    var contentMode: ContentMode
    
    let tailHeight = CGFloat(10)
    
    /// 이미지 마커 뷰를 생성합니다.
    /// - Parameters:
    ///   - contentMode: 이미지의 비율을 결정합니다.
    ///     * `.fill`: 일반 사진용 (꽉 채우기)
    ///     * `.fit`: 플레이스홀더/아이콘용 (전체 보이기)
    init(image: Image, title: String, contentMode: ContentMode = .fill) {
        self.image = image
        self.title = title
        self.contentMode = contentMode
    }
    
    var body: some View {
        VStack(spacing: 0) {
            ZStack(alignment: .bottom) {
                image
                    .resizable()
                    .aspectRatio(contentMode: contentMode)
                    .frame(width: 90, height: 70)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                
                Text(title)
                    .font(size: 13, font: .spoqa(.bold))
                    .foregroundColor(.white)
                    .lineLimit(1)
                    .padding(.bottom, 2.5)
                    .padding(.horizontal, 4)
                    .shadow(color: .black.opacity(0.8), radius: 1, x: 1, y: 1)
                    .shadow(color: .black.opacity(0.8), radius: 1, x: -1, y: -1)
            }
            .padding(4)
            .background(Color.white)
            .cornerRadius(16)
            
            Triangle()
                .fill(Color.white)
                .frame(width: 16, height: tailHeight)
                .padding(.top, -1) // 틈새 제거
        }
        .compositingGroup()
        .shadow(color: Color.black.opacity(0.15), radius: 3, x: 0, y: 2)
    }
}

#Preview("무스파타") {
    ImageMarkerView(image: Image(.mustafa), title: "무스타파", contentMode: .fill)
}

#Preview("placeholder") {
    ImageMarkerView(image: Image(.placeholder), title: "", contentMode: .fit)
}

