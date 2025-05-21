import ProjectDescription

let project = Project(
    name: "Mari",
    targets: [
        .target(
            name: "Mari",
            destinations: .iOS,
            product: .app,
            bundleId: "io.tuist.Mari",
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
            dependencies: []
        ),
        .target(
            name: "MariTests",
            destinations: .iOS,
            product: .unitTests,
            bundleId: "io.tuist.MariTests",
            infoPlist: .default,
            sources: ["Mari/Tests/**"],
            resources: [],
            dependencies: [.target(name: "Mari")]
        ),
    ]
)
