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
    
    // MARK: - Layout Constants
    enum Layout {
        static let imageSize = CGSize(width: 90, height: 70)
        static let tailSize = CGSize(width: 16, height: 10)
        static let containerPadding: CGFloat = 4
        static let tailOverlap: CGFloat = 1 // 꼬리와 몸통 사이 틈 제거용 겹침
        
        static let imageCornerRadius: CGFloat = 12
        static let containerCornerRadius: CGFloat = 16
        
        static let fontSize: CGFloat = 13
        static let textBottomPadding: CGFloat = 2.5
        static let textHorizontalPadding: CGFloat = 4
        
        static var totalHeightOffset: CGFloat {
            imageSize.height + (containerPadding * 2) + tailSize.height - tailOverlap
        }
    }
    
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
                    .frame(width: Layout.imageSize.width, height: Layout.imageSize.height)
                    .clipShape(RoundedRectangle(cornerRadius: Layout.imageCornerRadius))
                
                Text(title)
                    .font(size: Layout.fontSize, font: .spoqa(.bold))
                    .foregroundColor(.white)
                    .lineLimit(1)
                    .padding(.bottom, Layout.textBottomPadding)
                    .padding(.horizontal, Layout.textHorizontalPadding)
                    // 텍스트 가독성을 위한 그림자
                    .shadow(color: .black.opacity(0.8), radius: 1, x: 1, y: 1)
                    .shadow(color: .black.opacity(0.8), radius: 1, x: -1, y: -1)
            }
            .padding(Layout.containerPadding) // 흰색 테두리 역할
            .background(Color.white)
            .cornerRadius(Layout.containerCornerRadius)
            
            Triangle()
                .fill(Color.white)
                .frame(width: Layout.tailSize.width, height: Layout.tailSize.height)
                .padding(.top, -Layout.tailOverlap)
        }
        .compositingGroup() // 그림자를 전체에 적용
        .shadow(color: Color.black.opacity(0.15), radius: 3, x: 0, y: 2)
    }
}

#Preview("무스파타") {
    ImageMarkerView(image: Image(.mustafa), title: "무스타파", contentMode: .fill)
}

#Preview("placeholder") {
    ImageMarkerView(image: Image(.placeholder), title: "", contentMode: .fit)
}
