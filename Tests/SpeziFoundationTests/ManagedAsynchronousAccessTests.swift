//
// This source file is part of the Stanford Spezi open-source project
//
// SPDX-FileCopyrightText: 2024 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

@testable import SpeziFoundation
import Testing

struct ManagedAsynchronousAccessTests {
    @MainActor
    @Test
    func testResumeWithSuccess() async throws {
        let access = ManagedAsynchronousAccess<String, Error>()
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
            #expect(access.ongoingAccess == true)
            let didResume = access.resume(returning: expectedValue)

            #expect(didResume == false)
            #expect(access.ongoingAccess == false)
            
            await task.value
        }
    }
    
    @MainActor
    @Test
    func testResumeWithError() async throws {
        let access = ManagedAsynchronousAccess<String, Error>()

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
            #expect(access.ongoingAccess == true)
            let didResume = access.resume(throwing: TimeoutError())

            #expect(didResume == false)
            #expect(access.ongoingAccess == false)
            
            await task.value
        }
    }
    
    @MainActor
    @Test
    func testCancelAll() async throws {
        let access = ManagedAsynchronousAccess<Void, Error>()

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
            #expect(access.ongoingAccess == true)
            #expect(task.isCancelled == false)
            
            access.cancelAll()

            #expect(access.ongoingAccess == false)
            
            await task.value
            
            #expect(task.isCancelled, "Task should be marked as cancelled.")
        }
    }
    
    @MainActor
    @Test
    func testCancelAllNeverError() async throws {
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
            
            #expect(access.ongoingAccess == true)
            #expect(task.isCancelled == false)
            
            access.cancelAll()
            
            #expect(access.ongoingAccess == false)
            
            await task.value
            
            #expect(task.isCancelled, "Task should be marked as cancelled.")
        }
    }
    
    @Test
    func testResumeWithoutOngoingAccess() {
        let access = ManagedAsynchronousAccess<String, Error>()

        let didResume = access.resume(returning: "No Access")

        #expect(didResume == false)
    }
    
    @MainActor
    @Test
    func testResumeWithVoidValue() async throws {
        let access = ManagedAsynchronousAccess<Void, Never>()

        try await confirmation("perform() returns with cancellation error") { confirm in
            let task = Task {
                try await access.perform {}
                confirm()
            }
            
            try await Task.sleep(for: .milliseconds(100))
            
            #expect(access.ongoingAccess == true)
            
            let didResume = access.resume()
            
            #expect(didResume == false)
            #expect(access.ongoingAccess == false)
            
            try await task.value
        }
    }

    @MainActor
    @Test
    func testExclusiveAccess() async throws {
        let access = ManagedAsynchronousAccess<String, Error>()
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
                
                #expect(access.ongoingAccess == true)
                
                let didResume0 = access.resume(returning: expectedValue0)
                
                #expect(didResume0 == true)
                #expect(access.ongoingAccess == false)
                
                await task0.value
                
                try await Task.sleep(for: .milliseconds(100))
                
                #expect(access.ongoingAccess == true)
                
                let didResume1 = access.resume(returning: expectedValue1)
                
                #expect(didResume1 == false)
                #expect(access.ongoingAccess == false)

                await task1.value
            }
        }
    }
    
    @MainActor
    @Test
    func testExclusiveAccessNeverError() async throws {
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
                
                #expect(access.ongoingAccess == true)
                
                let didResume0 = access.resume(returning: expectedValue0)
                
                #expect(didResume0 == true)
                #expect(access.ongoingAccess == false)
                
                try await task0.value
                
                try await Task.sleep(for: .milliseconds(100))
                
                #expect(access.ongoingAccess == true)
                
                let didResume1 = access.resume(returning: expectedValue1)
                
                #expect(didResume1 == false)
                #expect(access.ongoingAccess == false)
                
                try await task1.value
            }
        }
    }
}
