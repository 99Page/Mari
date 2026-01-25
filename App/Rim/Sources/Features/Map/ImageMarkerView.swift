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
    
    let tailHeight = CGFloat(10)
    
    var body: some View {
        VStack(spacing: 0) {
            ZStack(alignment: .bottom) {
                // 배경 이미지
                image
                    .resizable()
                    .scaledToFill()
                    .frame(width: 90, height: 70)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                
                Text(title)
                    .font(size: 13, font: .spoqa(.bold))
                    .foregroundColor(.white)
                    .lineLimit(1)
                    .padding(.bottom, 2.5)
                    .padding(.horizontal, 4)
                    // 테두리 효과
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

#Preview {
    ImageMarkerView(image: Image(.mustafa), title: "무스타파")
}

