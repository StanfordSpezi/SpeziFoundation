// swift-tools-version:5.9

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
        .iOS(.v17),
        .watchOS(.v10),
        .visionOS(.v1),
        .macOS(.v14),
        .tvOS(.v17)
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
