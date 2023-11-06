// swift-tools-version:5.8

//
// This source file is part of the Stanford Spezi open-source project
// 
// SPDX-FileCopyrightText: 2022 Stanford University and the project authors (see CONTRIBUTORS.md)
// 
// SPDX-License-Identifier: MIT
//

import PackageDescription


let package = Package(
    name: "SpeziFoundation",
    platforms: [
        .iOS(.v16),
        .watchOS(.v9)
    ],
    products: [
        .library(name: "SpeziFoundation", targets: ["SpeziFoundation"])
    ],
    targets: [
        .target(
            name: "SpeziFoundation"
        ),
        .testTarget(
            name: "SpeziFoundationTests",
            dependencies: [
                .target(name: "SpeziFoundation")
            ]
        )
    ]
)
