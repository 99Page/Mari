//
//  Project.swift
//  AppManifests
//
//  Created by 노우영 on 6/11/25.
//

import ProjectDescription

let target = Target.target(
    name: "CoreApp",
    destinations: .iOS,
    product: .app,
    bundleId: "com.page.core.app",
    infoPlist: .extendingDefault(
        with: [
            "UILaunchScreen": [
                "UIColorName": "",
                "UIImageName": "",
            ],
            "UIApplicationSceneManifest": [
                "UIApplicationSupportsMultipleScenes": true,
                "UISceneConfigurations": [
                    "UIWindowSceneSessionRoleApplication": [
                        [
                            "UISceneConfigurationName": "Default Configuration",
                            "UISceneDelegateClassName": "$(PRODUCT_MODULE_NAME).SceneDelegate"
                        ]
                    ]
                ]
            ]
        ]
    ),
    sources: ["Sources/**"],
    resources: ["Resources/**"],
    dependencies: [
        .project(target: "Core", path: "../Core")
    ]
)


let project = Project(
    name: "CoreApp",
    targets: [
        target
    ]
)

