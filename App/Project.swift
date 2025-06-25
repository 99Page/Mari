import ProjectDescription


let infoPlist: [String: Plist.Value] = [
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

let target = Target.target(
    name: "Rim",
    destinations: .iOS,
    product: .app,
    bundleId: "com.page.rim",
    infoPlist: .extendingDefault(with: infoPlist),
    sources: ["Rim/Sources/**"],
    resources: ["Rim/Resources/**"],
    dependencies: [
        .package(product: "FirebaseAnalytics"),
        .package(product: "FirebaseAuth"),
        .package(product: "NMapsMap"),
        .package(product: "FirebaseStorage"),
        .package(product: "FirebaseCore"),
        .package(product: "FirebaseFirestore"),
        .package(product: "FirebaseFunctions"),
        .project(target: "Core", path: .relativeToRoot("Core")),
        .package(product: "ComposableArchitecture") // Core가 ComposableAchitecture를 의존 중입니다. -page 2025. 06. 18
    ]
)


let project = Project(
    name: "Rim",
    packages: [
        .remote(url: "https://github.com/navermaps/SPM-NMapsMap", requirement: .exact("3.21.0")),
        .remote(url: "https://github.com/firebase/firebase-ios-sdk", requirement: .exact("11.13.0")),
    ],
    targets: [
        target,
        .target(
            name: "RimTests",
            destinations: .iOS,
            product: .unitTests,
            bundleId: "com.page.rim.tests",
            infoPlist: .default,
            sources: ["Rim/Tests/**"],
            resources: [],
            dependencies: [.target(name: "Rim")]
        ),
    ]
)
