//
// This source file is part of the Stanford Spezi open-source project
//
// SPDX-FileCopyrightText: 2023 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import Foundation


/// Stores the globally accessible application environment.
///
/// The ``ApplicationEnvironmentRepository`` holds all values relevant to the global application environment.
/// ``ApplicationEnvironmentRepository/shared`` serves as a Singleton that the singular read-only existence of the ``ApplicationEnvironmentRepository``.
///
/// - Tip: Use the ``ApplicationEnvironment`` property wrapper `@ApplicationEnvironment` to access the ``ApplicationEnvironmentRepository`` conveniently.
///
/// ### Usage
/// ```swift
/// if ApplicationEnvironmentRepository.shared.testMode { /* ... */ }
/// ```
public struct ApplicationEnvironmentRepository: Sendable {
    /// Holds the globally accessible ``ApplicationEnvironmentRepository`` Singleton.
    public static let shared = ApplicationEnvironmentRepository()
    
    
    /// Indicates if the application is currently user test, for example a unit test or a UI test.
    /// Configurable by passing the `--testMode` flag as a command line argument to the application.
    public let testMode = ProcessInfo.processInfo.arguments.contains("--testMode")
    
    
    /// Private initializer so that the ``ApplicationEnvironmentRepository`` only exists once within the application.
    private init() {}
}


/// Convenient access to the ``ApplicationEnvironmentRepository``.
///
/// The `@ApplicationEnvironment` property wrapper enables SwiftUI-like access to the global application environment ``ApplicationEnvironmentRepository``.
/// The property wrapper is usable within any context and not bound to a SwiftUI `View` (as `@Environment` is).
///
/// ### Usage
///
/// ```swift
/// @ApplicationEnvironment var applicationEnvironment
///
/// if applicationEnvironment.testMode { /* ... */ }
/// ```
@propertyWrapper
public struct ApplicationEnvironment: Sendable {
    public var wrappedValue: ApplicationEnvironmentRepository {
        ApplicationEnvironmentRepository.shared
    }
    

    public init() {}
}
