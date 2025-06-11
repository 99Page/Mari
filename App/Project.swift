import ProjectDescription

let target = Target.target(
    name: "Mari",
    destinations: .iOS,
    product: .app,
    bundleId: "com.page.mari",
    infoPlist: .extendingDefault(
        with: [
            "NMFNcpKeyId": "s0lzvlyvnh", // https://navermaps.github.io/ios-map-sdk/guide-ko/1.html
            "UILaunchScreen": [
                "UIColorName": "",
                "UIImageName": "",
            ],
            "NSLocationAlwaysUsageDescription": "사용자의 위치 정보를 받습니다",
            "NSLocationWhenInUseUsageDescription": "사용자의 위치 정보를 받습니다",
            "NSCameraUsageDescription": "사진을 찍기 위해 카메라 접근이 필요합니다.",
            
            "UIApplicationSceneManifest": [
                "UIApplicationSupportsMultipleScenes": true,
                "UISceneConfigurations": [
                    // SceneDelegate가 동작하기 위해 필요한 키 값입니다.
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
    sources: ["Mari/Sources/**"],
    resources: ["Mari/Resources/**"],
    dependencies: [
        .package(product: "FirebaseAnalytics"),
        .package(product: "FirebaseStorage"),
        .package(product: "FirebaseAuth"),
        .package(product: "FirebaseCore"),
        .package(product: "NMapsMap"),
        .project(target: "Core", path: "../Core"),
    ]
)


let project = Project(
    name: "Mari",
    packages: [
        .remote(url: "https://github.com/firebase/firebase-ios-sdk", requirement: .exact("11.13.0")),
        .remote(url: "https://github.com/navermaps/SPM-NMapsMap", requirement: .exact("3.21.0"))
    ],
    targets: [
        target,
        .target(
            name: "MariTests",
            destinations: .iOS,
            product: .unitTests,
            bundleId: "com.page.mari.tests",
            infoPlist: .default,
            sources: ["Mari/Tests/**"],
            resources: [],
            dependencies: [.target(name: "Mari")]
        ),
    ]
)
