import ProjectDescription


let infoPlist: [String: Plist.Value] = [
    "NMFNcpKeyId": "s0lzvlyvnh", // https://navermaps.github.io/ios-map-sdk/guide-ko/1.html
    "UILaunchScreen": [
        "UIColorName": "",
        "UIImageName": "",
    ],
    "NSLocationAlwaysUsageDescription": "사진의 위치를 표시하기 위해 사용자의 위치 정보를 사용합니다.",
    "NSLocationWhenInUseUsageDescription": "사진의 위치를 표시하기 위해 사용자의 위치 정보를 사용합니다.",
    "NSCameraUsageDescription": "게시글의 이미지를 제공하기 위해 카메라를 사용합니다.",
    "UISupportedInterfaceOrientations": ["UIInterfaceOrientationPortrait"], // 세로 모드만 허용
    "UIUserInterfaceStyle": "Light", // 다크모드 끄기
    
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
            "CFBundleURLSchemes": [
                "com.googleusercontent.apps.944288474620-7pbohckkv136fdhfr0s8bt1rf0d0qv9d" // release
            ]
        ],
        [
            "CFBundleURLName": "GoogleSignIn-Dev",
            "CFBundleURLSchemes": [
                "com.googleusercontent.apps.637646465807-gs0sqkefc83oi84atssg6q39qducomc3" // dev
            ]
        ]
    ]
]

let target = Target.target(
    name: "Rim",
    destinations: [.iPhone],
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
        .package(product: "Geohash"),
        .project(target: "Core", path: .relativeToRoot("Core")),
        .package(product: "ComposableArchitecture") // Core가 ComposableAchitecture를 의존 중입니다. -page 2025. 06. 18
    ],
    settings: .settings(
        base: [
            "MARKETING_VERSION": "1.0.1",
            "CODE_SIGN_STYLE": "Automatic",
            "DEVELOPMENT_TEAM": "MAU8HFALP8", // 개인 개발 계정 ✅ 공개 상관 없는 값
            "ENABLE_SWIFT_MACROS": "YES"
        ],
        configurations: [
            .debug(name: "Debug", settings: [
                "PRODUCT_BUNDLE_IDENTIFIER": "com.page.rim.dev",
                "INFOPLIST_KEY_CFBundleDisplayName": "Rim Dev",
                "INFOPLIST_KEY_CFBundleName": "Rim Dev",
                "ASSETCATALOG_COMPILER_APPICON_NAME": "AppIcon-Dev"
            ]),
            .release(name: "Release", settings: [
                "PRODUCT_BUNDLE_IDENTIFIER": "com.page.rim",
                "INFOPLIST_KEY_CFBundleDisplayName": "Rim",
                "INFOPLIST_KEY_CFBundleName": "Rim",
                "ASSETCATALOG_COMPILER_APPICON_NAME": "AppIcon"
            ])
        ]
    )
)


let project = Project(
    name: "Rim",
    packages: [
        .remote(url: "https://github.com/navermaps/SPM-NMapsMap", requirement: .exact("3.21.0")),
        .remote(url: "https://github.com/firebase/firebase-ios-sdk", requirement: .exact("11.13.0")),
        .remote(url: "https://github.com/google/GoogleSignIn-iOS", requirement: .exact("8.0.0")),
        .remote(url: "https://github.com/nh7a/Geohash.git", requirement: .exact("1.0.0"))
        
    ],
    targets: [
        target,
        .target(
            name: "RimTests",
            destinations: [.iPhone],
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
