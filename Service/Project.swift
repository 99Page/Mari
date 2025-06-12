//
//  Service.swift
//  AppManifests
//
//  Created by 노우영 on 6/12/25.
//

import ProjectDescription

let target = Target.target(
    name: "Service",
    destinations: .iOS,
    product: .staticFramework,
    bundleId: "com.page.service",
    sources: ["Sources/**"],
    dependencies: [
        .project(target: "Core", path: "../Core"),
        .package(product: "FirebaseStorage"),
        .package(product: "FirebaseCore"),
    ]
)


let project = Project(
    name: "Service",
    packages: [
        .remote(url: "https://github.com/firebase/firebase-ios-sdk", requirement: .exact("11.13.0"))
    ],
    targets: [
        target
    ]
)


