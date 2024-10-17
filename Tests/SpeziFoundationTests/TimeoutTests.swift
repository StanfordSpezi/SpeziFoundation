//
// This source file is part of the Stanford Spezi open-source project
//
// SPDX-FileCopyrightText: 2024 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//


import SpeziFoundation
import XCTest


final class TimeoutTests: XCTestCase {
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
    func operationMethod(timeout: Duration, operation: Duration, timeoutExpectation: XCTestExpectation) async throws {
        let storage = storage
        async let _ = withTimeout(of: timeout) { @MainActor [storage] in
            XCTAssertFalse(Task.isCancelled)
            timeoutExpectation.fulfill()
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

    @MainActor
    func testTimeout() async throws {
        let negativeExpectation = XCTestExpectation()
        negativeExpectation.isInverted = true
        try await operationMethod(timeout: .seconds(1), operation: .milliseconds(500), timeoutExpectation: negativeExpectation)


        await fulfillment(of: [negativeExpectation], timeout: 2)

        let expectation = XCTestExpectation()
        do {
            try await operationMethod(timeout: .milliseconds(500), operation: .seconds(5), timeoutExpectation: expectation)
            XCTFail("Operation did unexpectedly complete!")
        } catch {
            XCTAssert(error is TimeoutError)
        }
        await fulfillment(of: [expectation])
    }
}
