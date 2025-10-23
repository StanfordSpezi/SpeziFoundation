//
// This source file is part of the Stanford Spezi open-source project
//
// SPDX-FileCopyrightText: 2024 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//


import Foundation
@testable import SpeziFoundation
import Testing

@Suite
struct TimeoutTests {
    @MainActor
    private final class Storage {
        var continuation: CheckedContinuation<Void, any Error>?
    }
    
    private let storage = Storage()
    
    @MainActor
    func operation(for duration: Duration) {
        Task { @MainActor in
            try? await Task.sleep(for: duration)
            if let continuation = storage.continuation {
                continuation.resume()
                storage.continuation = nil
            }
        }
    }
    
    @MainActor
    func operationMethod(timeout: Duration, operation: Duration) async throws {
        let storage = storage
        async let _ = withTimeout(of: timeout) { @MainActor [storage] in
            #expect(!Task.isCancelled)
            if let continuation = storage.continuation {
                storage.continuation = nil
                continuation.resume(throwing: TimeoutError())
            }
        }
        
        try await withCheckedThrowingContinuation { continuation in
            storage.continuation = continuation
            self.operation(for: operation)
        }
    }
    
    @Test("Operation finishes", .timeLimit(.minutes(1)))
    func completesWithinTimeout() async throws {
        try await confirmation("operation finishes") { confirmed in
            try await operationMethod(
                timeout: .seconds(1),
                operation: .milliseconds(500)
            )
            confirmed()
        }
    }
    
    @Test("Operation times out", .timeLimit(.minutes(1)))
    func throwsOnTimeout() async throws {
        await confirmation("operation times out") { confirmed in
            do {
                try await operationMethod(
                    timeout: .milliseconds(500),
                    operation: .seconds(5)
                )
            } catch {
                #expect(error is TimeoutError)
                confirmed()
            }
        }
    }
}
