//
//  PostSummaryState.swift
//  Rim
//
//  Created by 노우영 on 6/23/25.
//

import Core
import Foundation
import UIKit
import ComposableArchitecture
import SnapKit
import SwiftUI
import CoreLocation


class PostSummaryView: UIView, Previewable {
    
    @UIBinding var state: State
    
    let image: RimImageView
    let label: RimLabel
    
    init(state: UIBinding<State>) {
        self._state = state
        self.image = RimImageView(imageURL: state.imageURL)
        self.label = RimLabel(state: state.title)
        super.init(frame: .zero)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func configure() {
        makeConstraint()
        configureSubviews()
    }
    
    private func configureSubviews() {
        image.configure()
        label.configure()
    }
    
    private func makeConstraint() {
        addSubview(image)
        addSubview(label)
        
        image.snp.makeConstraints { make in
            make.top.leading.equalToSuperview()
        }
        
        label.snp.makeConstraints { make in
            make.top.equalTo(image.snp.bottom)
            make.leading.trailing.bottom.equalToSuperview()
        }
    }
    
    struct State {
        let id: String
        var title: RimLabel.State
        var imageURL: String?
        var location: CLLocation
        
        init(id: String, title: RimLabel.State, imageURL: String? = nil, location: CLLocation) {
            self.id = id 
            self.title = title
            self.imageURL = imageURL
            self.location = location
        }
        
        init(dto: PostDTO) {
            self.id = dto.id
            self.title = .init(text: dto.title, textColor: .black)
            self.imageURL = dto.imageUrl
            self.location = CLLocation(latitude: dto.location.latitude, longitude: dto.location.longitude)
        }
    }

}

@available(iOS 17.0, *)
#Preview {
    @Previewable @UIBinding var state = PostSummaryView.State(
        id: "id", title: .init(text: "title", textColor: .black),
        imageURL: "https://picsum.photos/200/300",
        location: CLLocation(latitude: 36.5, longitude: 127.5)
    )
    
    ViewPreview(fromY: \.centerY, toY: \.centerY) {
        PostSummaryView(state: $state)
    }
    .frame(width: 100, height: 100, alignment: .center)
}
