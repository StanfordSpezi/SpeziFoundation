//
// This source file is part of the Stanford Spezi open-source project
//
// SPDX-FileCopyrightText: 2024 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import SpeziFoundation
import XCTest


final class ManagedAsynchronousAccessTests: XCTestCase {
    @MainActor
    func testResumeWithSuccess() async throws {
        let access = ManagedAsynchronousAccess<String, Error>()
        let expectedValue = "Success"

        let expectation = XCTestExpectation(description: "task")

        Task {
            do {
                let value = try await access.perform {
                    // this is were you would trigger your operation
                }
                XCTAssertEqual(value, expectedValue)
            } catch {
                XCTFail("Unexpected error: \(error)")
            }
            expectation.fulfill()
        }

        try await Task.sleep(for: .milliseconds(100))

        XCTAssertTrue(access.ongoingAccess)

        let didResume = access.resume(returning: expectedValue)

        XCTAssertFalse(didResume)
        XCTAssertFalse(access.ongoingAccess)

        await fulfillment(of: [expectation])
    }

    @MainActor
    func testResumeWithError() async throws {
        let access = ManagedAsynchronousAccess<String, Error>()

        let expectation = XCTestExpectation(description: "task")
        Task {
            do {
                _ = try await access.perform {}
                XCTFail("Expected error, but got success.")
            } catch {
                XCTAssertTrue(error is TimeoutError)
            }
            expectation.fulfill()
        }

        try await Task.sleep(for: .milliseconds(100))

        XCTAssertTrue(access.ongoingAccess)

        // throw some error
        let didResume = access.resume(throwing: TimeoutError())

        XCTAssertFalse(didResume)
        XCTAssertFalse(access.ongoingAccess)

        await fulfillment(of: [expectation], timeout: 2.0)
    }

    @MainActor
    func testCancelAll() async throws {
        let access = ManagedAsynchronousAccess<Void, Error>()

        let expectation = XCTestExpectation(description: "task")
        Task {
            do {
                _ = try await access.perform {}
                XCTFail("Expected cancellation error.")
            } catch {
                XCTAssertTrue(error is CancellationError)
            }
            expectation.fulfill()
        }

        try await Task.sleep(for: .milliseconds(100))

        XCTAssertTrue(access.ongoingAccess)

        access.cancelAll()

        XCTAssertFalse(access.ongoingAccess)
        await fulfillment(of: [expectation])
    }

    @MainActor
    func testCancelAllNoError() async throws {
        let access = ManagedAsynchronousAccess<Void, Never>()

        let expectation = XCTestExpectation(description: "task")
        Task {
            try await access.perform {}
            expectation.fulfill()
        }

        try await Task.sleep(for: .milliseconds(100))

        XCTAssertTrue(access.ongoingAccess)

        access.cancelAll()

        XCTAssertFalse(access.ongoingAccess)
        await fulfillment(of: [expectation])
    }

    func testResumeWithoutOngoingAccess() {
        let access = ManagedAsynchronousAccess<String, Error>()

        let didResume = access.resume(returning: "No Access")

        XCTAssertFalse(didResume)
    }

    @MainActor
    func testResumeWithVoidValue() async throws {
        let access = ManagedAsynchronousAccess<Void, Never>()

        let expectation = XCTestExpectation(description: "task")
        Task {
            try await access.perform {}
            expectation.fulfill()
        }

        try await Task.sleep(for: .milliseconds(100))

        XCTAssertTrue(access.ongoingAccess)

        let didResume = access.resume()

        XCTAssertFalse(didResume)
        XCTAssertFalse(access.ongoingAccess)
        await fulfillment(of: [expectation])
    }


    @MainActor
    func testExclusiveAccess() async throws {
        let access = ManagedAsynchronousAccess<String, Error>()
        let expectedValue0 = "Success0"
        let expectedValue1 = "Success1"

        let expectation0 = XCTestExpectation(description: "task0")
        let expectation1 = XCTestExpectation(description: "task1")

        Task {
            do {
                let value = try await access.perform {}
                XCTAssertEqual(value, expectedValue0)
            } catch {
                XCTFail("Unexpected error: \(error)")
            }
            expectation0.fulfill()
        }

        try await Task.sleep(for: .milliseconds(100))

        Task {
            do {
                let value = try await access.perform {}
                XCTAssertEqual(value, expectedValue1)
            } catch {
                XCTFail("Unexpected error: \(error)")
            }
            expectation1.fulfill()
        }

        try await Task.sleep(for: .milliseconds(100))

        XCTAssertTrue(access.ongoingAccess)

        let didResume0 = access.resume(returning: expectedValue0)

        XCTAssertTrue(didResume0)
        XCTAssertFalse(access.ongoingAccess)

        await fulfillment(of: [expectation0])

        try await Task.sleep(for: .milliseconds(100))

        XCTAssertTrue(access.ongoingAccess)

        let didResume1 = access.resume(returning: expectedValue1)

        XCTAssertFalse(didResume1)
        XCTAssertFalse(access.ongoingAccess)

        await fulfillment(of: [expectation1])
    }

    @MainActor
    func testExclusiveAccessNoError() async throws {
        let access = ManagedAsynchronousAccess<String, Never>()
        let expectedValue0 = "Success0"
        let expectedValue1 = "Success1"

        let expectation0 = XCTestExpectation(description: "task0")
        let expectation1 = XCTestExpectation(description: "task1")

        Task {
            do {
                let value = try await access.perform {}
                XCTAssertEqual(value, expectedValue0)
            } catch {
                XCTFail("Unexpected error: \(error)")
            }
            expectation0.fulfill()
        }

        try await Task.sleep(for: .milliseconds(100))

        Task {
            do {
                let value = try await access.perform {}
                XCTAssertEqual(value, expectedValue1)
            } catch {
                XCTFail("Unexpected error: \(error)")
            }
            expectation1.fulfill()
        }

        try await Task.sleep(for: .milliseconds(100))

        XCTAssertTrue(access.ongoingAccess)

        let didResume0 = access.resume(returning: expectedValue0)

        XCTAssertTrue(didResume0)
        XCTAssertFalse(access.ongoingAccess)

        await fulfillment(of: [expectation0])

        try await Task.sleep(for: .milliseconds(100))

        XCTAssertTrue(access.ongoingAccess)

        let didResume1 = access.resume(returning: expectedValue1)

        XCTAssertFalse(didResume1)
        XCTAssertFalse(access.ongoingAccess)

        await fulfillment(of: [expectation1])
    }
}
