//
//  SceneDelegate.swift
//  Mari
//
//  Created by 노우영 on 5/26/25.
//

import Foundation
import UIKit
import ComposableArchitecture

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?

    func scene(_ scene: UIScene,
               willConnectTo session: UISceneSession,
               options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = (scene as? UIWindowScene) else { return }

        let window = UIWindow(windowScene: windowScene)
        
        let store = Store(initialState: MapNavigationStack.State()) {
            MapNavigationStack()
        }
        
        window.rootViewController = MapNavigationStackController(store: store)
        window.makeKeyAndVisible()
        self.window = window
    }
}
