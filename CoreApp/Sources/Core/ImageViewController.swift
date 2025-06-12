//
//  ImageViewController.swift
//  CoreApp
//
//  Created by 노우영 on 6/12/25.
//

import Foundation
import UIKit
import ComposableArchitecture
import SnapKit
import Core
import SwiftUI

struct State {
    let url: String
}

class ImageViewController: UIViewController {
    
    @UIBinding var url: String
    
    let image: RimImageView
    
    init(url: String) {
        @UIBinding var binding = url
        self.url = url
        self.image = RimImageView(imageURL: $binding)
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        makeConstraints()
        configure()
    }
    
    func configure() {
        image.configure()
    }
    
    func makeConstraints() {
        view.addSubview(image)
        
        image.snp.makeConstraints { make in
            make.centerX.centerY.equalToSuperview()
            make.width.height.equalTo(100)
        }
    }
}

@available(iOS 17.0, *)
#Preview {
    ViewPreview(fromY: \.centerY, toY: \.centerY) {
        ImagePlaceholderView(frame: .zero)
    }
}
