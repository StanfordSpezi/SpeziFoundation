//
// This source file is part of the Stanford Spezi open-source project
//
// SPDX-FileCopyrightText: 2025 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

@testable import SpeziFoundation
import Testing

@MainActor
@Suite
struct ManagedAsynchronousAccessTests {
    @Test
    func resumeWithSuccess() async throws {
        let access = ManagedAsynchronousAccess<String, any Error>()
        let expectedValue = "Success"

        try await confirmation("perform() returns with success") { confirm in
            let task = Task {
                do {
                    let value = try await access.perform {
                        // this is were you would trigger your operation
                    }
                    #expect(value == expectedValue)
                } catch {
                    Issue.record("Unexpected error: \(error)")
                }
                confirm()
            }
            
            try await Task.sleep(for: .milliseconds(100))
            #expect(access.ongoingAccess)
            let didResume = access.resume(returning: expectedValue)

            #expect(!didResume)
            #expect(!access.ongoingAccess)
            
            await task.value
        }
    }
    
    @Test
    func resumeWithError() async throws {
        let access = ManagedAsynchronousAccess<String, any Error>()

        try await confirmation("perform() returns with error") { confirm in
            let task = Task {
                do {
                    _ = try await access.perform { }
                    Issue.record("Expected error, but got success.")
                } catch {
                    #expect(error is TimeoutError)
                }
                confirm()
            }
            
            try await Task.sleep(for: .milliseconds(100))
            #expect(access.ongoingAccess)
            let didResume = access.resume(throwing: TimeoutError())

            #expect(!didResume)
            #expect(!access.ongoingAccess)
            
            await task.value
        }
    }
    
    @Test
    func cancelAll() async throws {
        let access = ManagedAsynchronousAccess<Void, any Error>()

        try await confirmation("perform() returns with cancellation error") { confirm in
            let task = Task {
                do {
                    _ = try await access.perform {}
                    Issue.record("Expected cancellation error.")
                } catch {
                    #expect(error is CancellationError)
                }
                confirm()
            }
            
            try await Task.sleep(for: .milliseconds(100))
            #expect(access.ongoingAccess)
            #expect(!task.isCancelled)
            
            access.cancelAll()

            #expect(!access.ongoingAccess)
            
            await task.value
            
            #expect(task.isCancelled, "Task should be marked as cancelled.")
        }
    }
    
    @Test
    func cancelAllNeverError() async throws {
        let access = ManagedAsynchronousAccess<Void, Never>()

        try await confirmation("perform() returns with cancellation error") { confirm in
            let task = Task {
                do {
                    try await access.perform {}
                    Issue.record("Expected cancellation to turn into a cancellation error")
                } catch {
                    #expect(error is CancellationError)
                }
                confirm()
            }
            
            try await Task.sleep(for: .milliseconds(100))
            
            #expect(access.ongoingAccess)
            #expect(!task.isCancelled)
            
            access.cancelAll()
            
            #expect(!access.ongoingAccess)
            
            await task.value
            
            #expect(task.isCancelled, "Task should be marked as cancelled.")
        }
    }
    
    @Test
    func resumeWithoutOngoingAccess() {
        let access = ManagedAsynchronousAccess<String, any Error>()

        let didResume = access.resume(returning: "No Access")

        #expect(!didResume)
    }
    
    @Test
    func resumeWithVoidValue() async throws {
        let access = ManagedAsynchronousAccess<Void, Never>()

        try await confirmation("perform() returns with cancellation error") { confirm in
            let task = Task {
                try await access.perform {}
                confirm()
            }
            
            try await Task.sleep(for: .milliseconds(100))
            
            #expect(access.ongoingAccess)
            
            let didResume = access.resume()
            
            #expect(!didResume)
            #expect(!access.ongoingAccess)
            
            try await task.value
        }
    }

    @Test
    func exclusiveAccess() async throws {
        let access = ManagedAsynchronousAccess<String, any Error>()
        let expectedValue0 = "Success0"
        let expectedValue1 = "Success1"

        try await confirmation("expectation of task0") { expectation0 in
            try await confirmation("expectation of task1") { expectation1 in
                let task0 = Task {
                    do {
                        let value = try await access.perform {}
                        #expect(value == expectedValue0)
                    } catch {
                        Issue.record("Unexpected error: \(error)")
                    }
                    expectation0()
                }
                
                try await Task.sleep(for: .milliseconds(100))
                
                let task1 = Task {
                    do {
                        let value = try await access.perform {}
                        #expect(value == expectedValue1)
                    } catch {
                        Issue.record("Unexpected error: \(error)")
                    }
                    expectation1()
                }
                
                try await Task.sleep(for: .milliseconds(100))
                
                #expect(access.ongoingAccess)
                
                let didResume0 = access.resume(returning: expectedValue0)
                
                #expect(didResume0)
                #expect(!access.ongoingAccess)
                
                await task0.value
                
                try await Task.sleep(for: .milliseconds(100))
                
                #expect(access.ongoingAccess)
                
                let didResume1 = access.resume(returning: expectedValue1)
                
                #expect(!didResume1)
                #expect(!access.ongoingAccess)

                await task1.value
            }
        }
    }
    
    @Test
    func exclusiveAccessNeverError() async throws {
        let access = ManagedAsynchronousAccess<String, Never>()
        let expectedValue0 = "Success0"
        let expectedValue1 = "Success1"
        try await confirmation("expectation of task0") { expectation0 in
            try await confirmation("expectation of task1") { expectation1 in
                let task0 = Task {
                    do {
                        let value = try await access.perform {}
                        #expect(value == expectedValue0)
                    } catch is CancellationError {
                        Issue.record("Unexpected error cancellation")
                    }
                    expectation0()
                }
                
                try await Task.sleep(for: .milliseconds(100))
                
                let task1 = Task {
                    do {
                        let value = try await access.perform {}
                        #expect(value == expectedValue1)
                    } catch is CancellationError {
                        Issue.record("Unexpected error cancellation")
                    }
                    expectation1()
                }
                
                try await Task.sleep(for: .milliseconds(100))
                
                #expect(access.ongoingAccess)
                
                let didResume0 = access.resume(returning: expectedValue0)
                
                #expect(didResume0)
                #expect(!access.ongoingAccess)
                
                try await task0.value
                
                try await Task.sleep(for: .milliseconds(100))
                
                #expect(access.ongoingAccess)
                
                let didResume1 = access.resume(returning: expectedValue1)
                
                #expect(!didResume1)
                #expect(!access.ongoingAccess)
                
                try await task1.value
            }
        }
    }
}


// MARK: - cancelAll()

extension ManagedAsynchronousAccessTests {
    /// `cancelAll()` must hand back the exclusive-access permit it was holding.
    ///
    /// The `cancelAll` tests above only check that the ongoing access is resumed with a cancellation
    /// error; they never use the access again, so a permit leaked here would go unnoticed and every
    /// subsequent `perform()` would wait forever.
    @Test
    func accessIsReusableAfterCancelAll() async throws {
        let access = ManagedAsynchronousAccess<Void, any Error>()

        let cancelled = Task { try await access.perform { } }
        try await Task.sleep(for: .milliseconds(100))
        #expect(access.ongoingAccess)
        access.cancelAll()
        _ = try? await cancelled.value

        // Bounded rather than a bare `await` on the task: if the permit was lost, `perform()` never
        // returns, and an unbounded wait would hang the suite instead of reporting a failure.
        let subsequent = Task { try await access.perform { } }
        var acquired = false
        for _ in 0..<50 where !acquired {
            try await Task.sleep(for: .milliseconds(20))
            acquired = access.ongoingAccess
        }
        #expect(acquired, "perform() could not acquire access after cancelAll()")

        if acquired {
            access.resume()
            try await subsequent.value
        } else {
            subsequent.cancel()
            _ = try? await subsequent.value
        }
    }

    /// `cancelAll()` must cancel *every* queued caller, not let one of them through.
    ///
    /// Returning the cancelled access's permit hands it to the first caller in line if that happens before
    /// the queue is cancelled, so the order of those two steps matters. With one holder and two queued
    /// callers, all three must observe cancellation and the access must be free afterwards.
    @Test
    func cancelAllCancelsEveryQueuedCaller() async throws {
        let access = ManagedAsynchronousAccess<Void, any Error>()

        let holder = Task { () -> Bool in
            do {
                try await access.perform { }
                return false
            } catch {
                return error is CancellationError
            }
        }
        try await Task.sleep(for: .milliseconds(50))
        let first = Task { () -> Bool in
            do {
                try await access.perform { }
                return false
            } catch {
                return error is CancellationError
            }
        }
        let second = Task { () -> Bool in
            do {
                try await access.perform { }
                return false
            } catch {
                return error is CancellationError
            }
        }
        try await Task.sleep(for: .milliseconds(50))
        #expect(access.ongoingAccess)

        access.cancelAll()

        // A caller that slipped through is now *holding* the access, so awaiting it would never return.
        // Check the observable state with a bounded wait instead, then release whatever is still held so
        // the tasks can finish and the failure is reported rather than hung.
        var settled = false
        for _ in 0..<50 where !settled {
            try await Task.sleep(for: .milliseconds(20))
            settled = !access.ongoingAccess
        }
        #expect(settled, "a queued caller slipped through cancelAll() and now holds the access")
        if !settled {
            access.resume()
        }

        let (holderCancelled, firstCancelled, secondCancelled) = await (holder.value, first.value, second.value)
        #expect(holderCancelled)
        #expect(firstCancelled, "the first queued caller was not cancelled by cancelAll()")
        #expect(secondCancelled)
    }
}
