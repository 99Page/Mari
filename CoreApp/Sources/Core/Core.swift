//
//  Core.swift
//  CoreApp
//
//  Created by 노우영 on 6/12/25.
//

import Foundation
import UIKit
import ComposableArchitecture

struct Core {
    let title: String
    let viewController: UIViewController
    
    static func cores() -> [Core] {
        [
            Core(title: "Image", viewController: ImageViewController(url: ["https://picsum.photos/200/300", ""])),
            
            Core(title: "AddAction", viewController: AddActionViewController()),
            
            Core(title: "Label", viewController: LabelViewController()),
            
            Core(
                title: "TextView",
                viewController: TextViewController(store: Store(initialState: TextViewFeature.State(), reducer: {
                    TextViewFeature()
                }))
            )
        ]
    }
}
