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
        .macCatalyst(.v17),
        .tvOS(.v17)
    ],
    products: [
        .library(name: "SpeziFoundation", targets: ["SpeziFoundation"]),
        .library(name: "SpeziLocalization", targets: ["SpeziLocalization"])
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-atomics.git", from: "1.2.0"),
        .package(url: "https://github.com/apple/swift-algorithms.git", from: "1.2.0"),
        .package(url: "https://github.com/StanfordBDHG/XCTRuntimeAssertions.git", from: "2.2.0"),
        .package(url: "https://github.com/apple/swift-log", from: "1.6.0"),
        .package(url: "https://github.com/facebook/zstd.git", revision: "88ff5c27694bdb89169383ac9fd14a6cddacc7ef"),
        .package(url: "https://github.com/StanfordBDHG/ThreadLocal.git", from: "0.1.0")
    ] + swiftLintPackage(),
    targets: [
        .systemLibrary(
            name: "CZlib",
            path: "Sources/CZlib",
            pkgConfig: "zlib",
            providers: [.apt(["zlib1g-dev"])]
        ),
        .target(
            name: "SpeziFoundation",
            dependencies: [
                .target(name: "SpeziFoundationObjC"),
                .target(name: "CZlib", condition: .when(platforms: [.linux])),
                .product(name: "libzstd", package: "zstd"),
                .product(name: "Atomics", package: "swift-atomics"),
                .product(name: "Algorithms", package: "swift-algorithms"),
                .product(name: "RuntimeAssertions", package: "XCTRuntimeAssertions"),
                .product(name: "Logging", package: "swift-log"),
                .product(name: "ThreadLocal", package: "ThreadLocal")
            ],
            resources: [
                .process("Resources")
            ],
            swiftSettings: [
                .enableUpcomingFeature("ExistentialAny"),
                .enableUpcomingFeature("InternalImportsByDefault")
            ],
            plugins: [] + swiftLintPlugin()
        ),
        .target(
            name: "SpeziFoundationObjC"
        ),
        .target(
            name: "SpeziLocalization",
            dependencies: [
                .target(name: "SpeziFoundation"),
                .product(name: "Algorithms", package: "swift-algorithms")
            ],
            swiftSettings: [
                .enableUpcomingFeature("ExistentialAny"),
                .enableUpcomingFeature("InternalImportsByDefault")
            ],
            plugins: [] + swiftLintPlugin()
        ),
        .testTarget(
            name: "SpeziFoundationTests",
            dependencies: [
                .target(name: "SpeziFoundation"),
                .product(name: "RuntimeAssertionsTesting", package: "XCTRuntimeAssertions")
            ],
            swiftSettings: [.enableUpcomingFeature("ExistentialAny")],
            plugins: [] + swiftLintPlugin()
        ),
        .testTarget(
            name: "SpeziLocalizationTests",
            dependencies: [
                .target(name: "SpeziLocalization"),
                .target(name: "SpeziFoundation")
            ],
            resources: [
                .process("Resources")
            ],
            swiftSettings: [.enableUpcomingFeature("ExistentialAny")],
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
