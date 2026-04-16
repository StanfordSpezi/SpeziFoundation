// swift-tools-version:6.2

//
// This source file is part of the Stanford Spezi open-source project
// 
// SPDX-FileCopyrightText: 2022 Stanford University and the project authors (see CONTRIBUTORS.md)
// 
// SPDX-License-Identifier: MIT
//

import CompilerPluginSupport
import class Foundation.ProcessInfo
import PackageDescription

/// Whether the package should run SwiftLint as part of its build process.
///
/// Set this to `false` before committing any changes.
let enableSwiftLintPlugin = false


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
        .package(url: "https://github.com/StanfordBDHG/zstd.git", exact: "1.5.8-beta.1"),
        .package(url: "https://github.com/StanfordBDHG/ThreadLocal.git", from: "0.1.0"),
        .package(url: "https://github.com/swiftlang/swift-syntax.git", "602.0.0"..<"604.0.0")
    ] + swiftLintPackage,
    targets: [
        .systemLibrary(
            name: "SpeziCZlib",
            path: "Sources/CZlib",
            pkgConfig: "zlib",
            providers: [.apt(["zlib1g-dev"])]
        ),
        .target(
            name: "SpeziFoundation",
            dependencies: [
                "SpeziFoundationObjC",
                "SpeziFoundationMacros",
                .target(name: "SpeziCZlib", condition: .when(platforms: [.linux])),
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
            plugins: [] + swiftLintPlugin
        ),
        .target(
            name: "SpeziFoundationObjC"
        ),
        .target(
            name: "SpeziLocalization",
            dependencies: [
                "SpeziFoundation",
                .product(name: "Algorithms", package: "swift-algorithms")
            ],
            swiftSettings: [
                .enableUpcomingFeature("ExistentialAny"),
                .enableUpcomingFeature("InternalImportsByDefault")
            ],
            plugins: [] + swiftLintPlugin
        ),
        .macro(
            name: "SpeziFoundationMacros",
            dependencies: [
                .product(name: "SwiftSyntaxMacros", package: "swift-syntax"),
                .product(name: "SwiftCompilerPlugin", package: "swift-syntax"),
                .product(name: "SwiftDiagnostics", package: "swift-syntax")
            ],
            swiftSettings: [.enableUpcomingFeature("ExistentialAny")],
            plugins: [] + swiftLintPlugin
        ),
        .testTarget(
            name: "SpeziFoundationTests",
            dependencies: [
                "SpeziFoundation",
                .product(name: "RuntimeAssertionsTesting", package: "XCTRuntimeAssertions")
            ],
            swiftSettings: [.enableUpcomingFeature("ExistentialAny")],
            plugins: [] + swiftLintPlugin
        ),
        .testTarget(
            name: "SpeziLocalizationTests",
            dependencies: [
                "SpeziLocalization",
                "SpeziFoundation"
            ],
            resources: [
                .process("Resources")
            ],
            swiftSettings: [.enableUpcomingFeature("ExistentialAny")],
            plugins: [] + swiftLintPlugin
        ),
        .testTarget(
            name: "SpeziFoundationMacrosTests",
            dependencies: [
                "SpeziFoundationMacros",
                .product(name: "SwiftSyntaxMacros", package: "swift-syntax"),
                .product(name: "SwiftSyntaxMacrosTestSupport", package: "swift-syntax")
            ],
            swiftSettings: [.enableUpcomingFeature("ExistentialAny")],
            plugins: [] + swiftLintPlugin
        )
    ]
)


// MARK: SwiftLint support

var swiftLintPlugin: [Target.PluginUsage] {
    if enableSwiftLintPlugin {
        [.plugin(name: "SwiftLintBuildToolPlugin", package: "SwiftLintPlugins")]
    } else {
        []
    }
}

var swiftLintPackage: [PackageDescription.Package.Dependency] {
    if enableSwiftLintPlugin {
        [.package(url: "https://github.com/SimplyDanny/SwiftLintPlugins.git", from: "0.63.2")]
    } else {
        []
    }
}
