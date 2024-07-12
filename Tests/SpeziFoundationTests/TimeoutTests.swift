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
    @MainActor private var continuation: CheckedContinuation<Void, any Error>?

    @MainActor
    func operation(for duration: Duration) {
        Task { @MainActor in
            try? await Task.sleep(for: duration)
            if let continuation = self.continuation {
                continuation.resume()
                self.continuation = nil
            }
        }
    }

    @MainActor
    func operationMethod(timeout: Duration, operation: Duration, timeoutExpectation: XCTestExpectation) async throws {
        async let _ = withTimeout(of: timeout) { @MainActor in
            timeoutExpectation.fulfill()
            if let continuation {
                continuation.resume(throwing: TimeoutError())
                self.continuation = nil
            }
        }

        try await withCheckedThrowingContinuation { continuation in
            self.continuation = continuation
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
