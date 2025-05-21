import ProjectDescription

let project = Project(
    name: "Mari",
    packages: [
        .remote(url: "https://github.com/firebase/firebase-ios-sdk", requirement: .exact("11.13.0"))
    ],
    targets: [
        .target(
            name: "Mari",
            destinations: .iOS,
            product: .app,
            bundleId: "com.page.mari",
            infoPlist: .extendingDefault(
                with: [
                    "UILaunchScreen": [
                        "UIColorName": "",
                        "UIImageName": "",
                    ],
                ]
            ),
            sources: ["Mari/Sources/**"],
            resources: ["Mari/Resources/**"],
            dependencies: [
                .package(product: "FirebaseAnalytics"),
                .package(product: "FirebaseStorage"),
                .package(product: "FirebaseAuth"),
                .package(product: "FirebaseCore")
            ]
        ),
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
