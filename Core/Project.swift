//
//  Project.swift
//  AppManifests
//
//  Created by 노우영 on 5/29/25.
//

import ProjectDescription

let projectName = "Core"

let target = Target.target(
    name: projectName,
    destinations: .iOS,
    product: .staticFramework,
    bundleId: "com.page.core",
    deploymentTargets: .iOS("17.0"),
    sources: ["Sources/**"],
    resources: ["Resources/**"],
    dependencies: [
        .package(product: "SnapKit"),
        .package(product: "ComposableArchitecture")
    ]
)

let testTarget = Target.target(
    name: "\(projectName)Tests",
    destinations: .iOS,
    product: .unitTests,
    bundleId: "com.page.pageKit.tests",
    deploymentTargets: .iOS("17.0"),
    sources: ["Tests/**"],
    dependencies: [
        .target(name: projectName)
    ]
)


let project = Project(
    name: projectName,
    organizationName: "Page",
    packages: [
        .remote(url: "https://github.com/SnapKit/SnapKit.git", requirement: .exact("5.7.1")),
        .remote(url: "https://github.com/pointfreeco/swift-composable-architecture.git", requirement: .exact("1.20.1"))
    ],
    targets: [target, testTarget]
)
