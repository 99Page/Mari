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
    ],
    
    "CFBundleURLTypes": [
        [
            "CFBundleURLName": "GoogleSignIn",
            "CFBundleURLSchemes":
                // GoogleService-Info.plist - REVERSED_CLIENT_ID 값
                ["com.googleusercontent.apps.944288474620-7pbohckkv136fdhfr0s8bt1rf0d0qv9d"]
        ]
    ]
]

let target = Target.target(
    name: "Rim",
    destinations: .iOS,
    product: .app,
    bundleId: "com.page.rim",
    deploymentTargets: .iOS("17.0"),
    infoPlist: .extendingDefault(with: infoPlist),
    sources: ["Rim/Sources/**"],
    resources: ["../Core/Resources/**"],
    entitlements: "SupportingFiles/Rim.entitlements",
    dependencies: [
        .package(product: "GoogleSignIn"),
        .package(product: "FirebaseAnalytics"),
        .package(product: "FirebaseAuth"),
        .package(product: "NMapsMap"),
        .package(product: "FirebaseStorage"),
        .package(product: "FirebaseCore"),
        .package(product: "FirebaseFirestore"),
        .package(product: "FirebaseFunctions"),
        .project(target: "Core", path: .relativeToRoot("Core")),
        .package(product: "ComposableArchitecture") // Core가 ComposableAchitecture를 의존 중입니다. -page 2025. 06. 18
    ],
    settings: .settings(
        base: [
            "CODE_SIGN_STYLE": "Automatic",
            "DEVELOPMENT_TEAM": "MAU8HFALP8", // 개인 개발 계정 ✅ 공개 상관 없는 값
            "ENABLE_SWIFT_MACROS": "YES"
        ]
    )
)


let project = Project(
    name: "Rim",
    packages: [
        .remote(url: "https://github.com/navermaps/SPM-NMapsMap", requirement: .exact("3.21.0")),
        .remote(url: "https://github.com/firebase/firebase-ios-sdk", requirement: .exact("11.13.0")),
        .remote(url: "https://github.com/google/GoogleSignIn-iOS", requirement: .exact("8.0.0"))
        
    ],
    targets: [
        target,
        .target(
            name: "RimTests",
            destinations: .iOS,
            product: .unitTests,
            bundleId: "com.page.rim.tests",
            deploymentTargets: .iOS("17.0"),
            infoPlist: .default,
            sources: ["Rim/Tests/**"],
            resources: [],
            dependencies: [.target(name: "Rim")]
        ),
    ]
)
