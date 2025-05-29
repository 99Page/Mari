//
//  File.swift
//  Core
//
//  Created by 노우영 on 5/29/25.
//  Copyright © 2025 Page. All rights reserved.
//

import Foundation
import UIKit
import SwiftUI
import SnapKit

struct ViewControllerPreview<T: UIViewController>: UIViewControllerRepresentable {
    private let viewController: T
    private var wrapInNavigation: Bool = false

    init(_ builder: @escaping () -> T) {
        self.viewController = builder()
    }

    func makeUIViewController(context: Context) -> UIViewController {
        return wrapInNavigation ? UINavigationController(rootViewController: viewController) : viewController
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}

    func dark() -> some View {
        self
            .ignoresSafeArea()
            .environment(\.colorScheme, .dark)
    }

    func navigation() -> ViewControllerPreview {
        var newPreview = self
        newPreview.wrapInNavigation = true
        return newPreview
    }
}

/// UIView를 UIViewController에 넣어 SwiftUI에서 미리보기 위한 구조체
struct ViewPreview<T: Previewable>: UIViewControllerRepresentable {
    let view: T
    
    let from: KeyPath<ConstraintMaker, ConstraintMakerExtendable>
    let to: KeyPath<ConstraintLayoutGuideDSL, ConstraintItem>
    
    init(fromY: KeyPath<ConstraintMaker, ConstraintMakerExtendable>, toY: KeyPath<ConstraintLayoutGuideDSL, ConstraintItem>, _ builder: @escaping () -> T) {
        self.view = builder()
        self.from = fromY
        self.to = toY
    }

    func makeUIViewController(context: Context) -> UIViewController {
        let viewController = UIViewController()
        view.translatesAutoresizingMaskIntoConstraints = false
        viewController.view.addSubview(view)

        view.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview()
            make[keyPath: from].equalTo(viewController.view.safeAreaLayoutGuide.snp[keyPath: to])
        }
        
        view.configure()
        
        return viewController
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) { }
}

protocol Previewable: UIView {
    func configure()
}
