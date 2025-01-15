// swift-tools-version:6.0

//
// This source file is part of the Stanford Spezi open-source project
// 
// SPDX-FileCopyrightText: 2022 Stanford University and the project authors (see CONTRIBUTORS.md)
// 
// SPDX-License-Identifier: MIT
//

import class Foundation.ProcessInfo
import PackageDescription


let package = Package(
    name: "SpeziFoundation",
    defaultLocalization: "en",
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
    dependencies: [
        .package(url: "https://github.com/apple/swift-atomics.git", from: "1.2.0"),
        .package(url: "https://github.com/apple/swift-algorithms", from: "1.2.0"),
        .package(url: "https://github.com/StanfordBDHG/XCTRuntimeAssertions", from: "1.1.3")
    ] + swiftLintPackage(),
    targets: [
        .target(
            name: "SpeziFoundation",
            dependencies: [
                .target(name: "SpeziFoundationObjC"),
                .product(name: "Atomics", package: "swift-atomics"),
                .product(name: "Algorithms", package: "swift-algorithms"),
                .product(name: "XCTRuntimeAssertions", package: "XCTRuntimeAssertions")
            ],
            resources: [
                .process("Resources")
            ],
            plugins: [] + swiftLintPlugin()
        ),
        .target(
            name: "SpeziFoundationObjC",
            sources: nil
        ),
        .testTarget(
            name: "SpeziFoundationTests",
            dependencies: [
                .target(name: "SpeziFoundation"),
                .product(name: "XCTRuntimeAssertions", package: "XCTRuntimeAssertions")
            ],
            plugins: [] + swiftLintPlugin()
        )
    ]
)


func swiftLintPlugin() -> [Target.PluginUsage] {
    // Fully quit Xcode and open again with `open --env SPEZI_DEVELOPMENT_SWIFTLINT /Applications/Xcode.app`
    if ProcessInfo.processInfo.environment["SPEZI_DEVELOPMENT_SWIFTLINT"] != nil {
        [.plugin(name: "SwiftLintBuildToolPlugin", package: "SwiftLint")]
    } else {
        []
    }
}

func swiftLintPackage() -> [PackageDescription.Package.Dependency] {
    if ProcessInfo.processInfo.environment["SPEZI_DEVELOPMENT_SWIFTLINT"] != nil {
        [.package(url: "https://github.com/realm/SwiftLint.git", from: "0.55.1")]
    } else {
        []
    }
}
