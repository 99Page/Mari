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
    deploymentTargets: .iOS("16.0"),
    sources: ["Sources/**"],
    dependencies: [
        .package(product: "SnapKit"),
    ]
)

let testTarget = Target.target(
    name: "\(projectName)Tests",
    destinations: .iOS,
    product: .unitTests,
    bundleId: "com.page.pageKit.tests",
    deploymentTargets: .iOS("16.0"),
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
    ],
    targets: [target, testTarget]
)
