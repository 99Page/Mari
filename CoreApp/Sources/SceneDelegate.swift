//
//  SceneDelegate.swift
//  CoreApp
//
//  Created by 노우영 on 6/11/25.
//

import Foundation
import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?

    func scene(_ scene: UIScene,
               willConnectTo session: UISceneSession,
               options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = (scene as? UIWindowScene) else { return }
        
        debugPrint("setup root")
        let window = UIWindow(windowScene: windowScene)
        window.rootViewController = UINavigationController(rootViewController: ListViewController())
        window.makeKeyAndVisible()
        self.window = window
    }
}
