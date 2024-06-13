//
// This source file is part of the Stanford Spezi open-source project
//
// SPDX-FileCopyrightText: 2024 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import Foundation


/// Timeout occurred inside an async operation.
public struct TimeoutError {
    /// Create a new timeout error.
    public init() {}
}


extension TimeoutError: Error {}


/// Race a timeout.
///
/// This method can be used to race an operation against a timeout.
///
/// ### Timeout in Async Context
///
/// Below is a code example showing how to best use the `withTimeout(of:perform:)` method in an async method.
/// The example uses [Structured Concurrency](https://docs.swift.org/swift-book/documentation/the-swift-programming-language/concurrency)
/// creating a child task running the timeout task. This makes sure that the timeout is automatically cancelled when the method goes out of scope.
///
/// ```swift
/// func foo() async throws {
///     async let _ = withTimeout(of: .seconds(30)) {
///         // cancel `operation` method below (e.g., resume continuation by throwing a `TimeoutError`)
///     }
///
///     try await operation()
/// }
/// ```
///
/// ### Timeout in Sync Context
///
/// Using `withTimeout(of:perform:)` in a synchronous method is similar. However, you will need to take care of cancellation yourself.
///
/// ```swift
/// func foo() throws {
///     let timeoutTask = Task {
///         await withTimeout(of: .seconds(30)) {
///             // cancel operation ...
///         }
///     }
///
///     defer {
///         timeoutTask.cancel()
///     }
///
///     try operation()
/// }
/// ```
///
/// - Parameters:
///   - timeout: The duration of the timeout.
///   - action: The action to run once the timeout passed.
public func withTimeout(of timeout: Duration, perform action: () async -> Void) async {
    try? await Task.sleep(for: timeout)
    guard !Task.isCancelled else {
        return
    }

    await action()
}
