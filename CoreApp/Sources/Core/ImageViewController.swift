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
    
    @UIBinding var url: [String?]
    
    let stackView = UIStackView()
    var imageViews: [RimImageView] = []
    private let button = UIButton(type: .custom)
    
    init(url: [String]) {
        self.url = url
        
        super.init(nibName: nil, bundle: nil)
        
        for index in self.url.indices {
            imageViews.append(RimImageView(imageURL: $url[index]))
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        makeConstraints()
        setupView()
        configure()
    }
    
    private func setupView() {
        stackView.axis = .vertical
        stackView.spacing = 16
        stackView.alignment = .center
        stackView.distribution = .equalSpacing
        
        button.setTitle("set url", for: .normal)
        button.setTitleColor(.black, for: .normal)
        button.addAction(UIAction(handler: { _ in
            self.url[1] = "https://picsum.photos/200/300"
        }), for: .touchUpInside)
    }
    
    func configure() {
        for imageView in imageViews {
            imageView.configure()
        }
    }
    
    func makeConstraints() {
        view.addSubview(stackView)
        
        imageViews.forEach { stackView.addArrangedSubview($0) }
        stackView.addArrangedSubview(button)
        
        stackView.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
        
        stackView.arrangedSubviews.forEach {
            $0.snp.makeConstraints { make in
                make.width.height.equalTo(100)
            }
        }
    }
}

@available(iOS 17.0, *)
#Preview {
    ViewPreview(fromY: \.centerY, toY: \.centerY) {
        ImagePlaceholderView(frame: .zero)
    }
}
