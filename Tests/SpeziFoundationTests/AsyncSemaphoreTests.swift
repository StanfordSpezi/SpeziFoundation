//
// This source file is part of the Stanford Spezi open-source project
//
// SPDX-FileCopyrightText: 2024 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//
// Tests adopted from https://github.com/groue/Semaphore/blob/main/Sources/Semaphore/AsyncSemaphore.swift.
//

import Dispatch
@testable import SpeziFoundation
import XCTest


final class AsyncSemaphoreTests: XCTestCase {
    func testSignalWithoutSuspendedTasks() {
        let dispatchSemZero = DispatchSemaphore(value: 0)
        XCTAssertFalse(dispatchSemZero.signal() != 0)
        
        let dispatchSemOne = DispatchSemaphore(value: 1)
        XCTAssertFalse(dispatchSemOne.signal() != 0)
        
        let dispatchSemTwo = DispatchSemaphore(value: 2)
        XCTAssertFalse(dispatchSemTwo.signal() != 0)

        let asyncSemZero = AsyncSemaphore(value: 0)
        let wokenZero = asyncSemZero.signal()
        XCTAssertFalse(wokenZero)
        
        let asyncSemOne = AsyncSemaphore(value: 1)
        let wokenOne = asyncSemOne.signal()
        XCTAssertFalse(wokenOne)
        
        let asyncSemTwo = AsyncSemaphore(value: 2)
        let wokenTwo = asyncSemTwo.signal()
        XCTAssertFalse(wokenTwo)
    }
    
    func testSignalReturnsWhetherItResumesSuspendedTask() async throws {
        let delay: Duration = .milliseconds(500)
        
        // Check DispatchSemaphore behavior
        do {
            // Given a thread waiting for the semaphore
            let sem = DispatchSemaphore(value: 0)
            Thread { sem.wait() }.start()
            try await Task.sleep(for: delay)
            
            // First signal wakes the waiting thread
            XCTAssertTrue(sem.signal() != 0)
            // Second signal does not wake any thread
            XCTAssertFalse(sem.signal() != 0)
        }
        
        // Test that AsyncSemaphore behaves identically
        do {
            // Given a task suspended on the semaphore
            let sem = AsyncSemaphore(value: 0)
            Task { await sem.wait() }
            try await Task.sleep(for: delay)
            
            // First signal resumes the suspended task
            XCTAssertTrue(sem.signal())
            // Second signal does not resume any task
            XCTAssertFalse(sem.signal())
        }
    }

    func testWaitSuspendsOnZeroSemaphoreUntilSignal() {
        // Check DispatchSemaphore behavior
        do {
            // Given a zero semaphore
            let sem = DispatchSemaphore(value: 0)
            
            // When a thread waits for this semaphore,
            let ex1 = expectation(description: "wait")
            ex1.isInverted = true
            let ex2 = expectation(description: "woken")
            Thread {
                sem.wait()
                ex1.fulfill()
                ex2.fulfill()
            }.start()
            
            // Then the thread is initially blocked.
            wait(for: [ex1], timeout: 0.5)
            
            // When a signal occurs, then the waiting thread is woken.
            sem.signal()
            wait(for: [ex2], timeout: 1)
        }
        
        // Test that AsyncSemaphore behaves identically
        do {
            // Given a zero semaphore
            let sem = AsyncSemaphore(value: 0)
            
            // When a task waits for this semaphore,
            let ex1 = expectation(description: "wait")
            ex1.isInverted = true
            let ex2 = expectation(description: "woken")
            Task {
                await sem.wait()
                ex1.fulfill()
                ex2.fulfill()
            }
            
            // Then the task is initially suspended.
            wait(for: [ex1], timeout: 0.5)
            
            // When a signal occurs, then the suspended task is resumed.
            sem.signal()
            wait(for: [ex2], timeout: 0.5)
        }
    }
    
    func testCancellationWhileSuspendedThrowsCancellationError() async throws {
        let sem = AsyncSemaphore(value: 0)
        let ex = expectation(description: "cancellation")
        let task = Task {
            do {
                try await sem.waitCheckingCancellation()
                XCTFail("Expected CancellationError")
            } catch is CancellationError {
            } catch {
                XCTFail("Unexpected error")
            }
            ex.fulfill()
        }
        try await Task.sleep(for: .milliseconds(100))
        task.cancel()
        await fulfillment(of: [ex], timeout: 1)
    }
    
    func testCancellationBeforeSuspensionThrowsCancellationError() throws {
        let sem = AsyncSemaphore(value: 0)
        let ex = expectation(description: "cancellation")
        let task = Task {
            // Uncancellable delay
            await withUnsafeContinuation { continuation in
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    continuation.resume()
                }
            }
            do {
                try await sem.waitCheckingCancellation()
                XCTFail("Expected CancellationError")
            } catch is CancellationError {
            } catch {
                XCTFail("Unexpected error")
            }
            ex.fulfill()
        }
        task.cancel()
        wait(for: [ex], timeout: 5)
    }
    
    func testCancellationWhileSuspendedIncrementsSemaphore() async throws {
        // Given a task cancelled while suspended on a semaphore,
        let sem = AsyncSemaphore(value: 0)
        let task = Task {
            try await sem.waitCheckingCancellation()
        }
        try await Task.sleep(for: .milliseconds(100))
        task.cancel()
        
        // When a task waits for this semaphore,
        let ex1 = expectation(description: "wait")
        ex1.isInverted = true
        let ex2 = expectation(description: "woken")
        Task {
            await sem.wait()
            ex1.fulfill()
            ex2.fulfill()
        }
        
        // Then the task is initially suspended.
        await fulfillment(of: [ex1], timeout: 0.5)
        
        // When a signal occurs, then the suspended task is resumed.
        sem.signal()
        await fulfillment(of: [ex2], timeout: 0.5)
    }
    
    func testCancellationBeforeSuspensionIncrementsSemaphore() throws {
        // Given a task cancelled before it waits on a semaphore,
        let sem = AsyncSemaphore(value: 0)
        let task = Task {
            // Uncancellable delay
            await withUnsafeContinuation { continuation in
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    continuation.resume()
                }
            }
            try await sem.waitCheckingCancellation()
        }
        task.cancel()
        
        // When a task waits for this semaphore,
        let ex1 = expectation(description: "wait")
        ex1.isInverted = true
        let ex2 = expectation(description: "woken")
        Task {
            await sem.wait()
            ex1.fulfill()
            ex2.fulfill()
        }
        
        // Then the task is initially suspended.
        wait(for: [ex1], timeout: 0.5)
        
        // When a signal occurs, then the suspended task is resumed.
        sem.signal()
        wait(for: [ex2], timeout: 0.5)
    }
    
    func testSemaphoreAsAResourceLimiterOnActorMethod() async {
        /// An actor that limits the number of concurrent executions of
        /// its `run()` method, and counts the effective number of
        /// concurrent executions for testing purpose.
        actor Runner {
            private let semaphore: AsyncSemaphore
            private var count = 0
            private(set) var effectiveMaxConcurrentRuns = 0
            
            init(maxConcurrentRuns: Int) {
                semaphore = AsyncSemaphore(value: maxConcurrentRuns)
            }
            
            func run() async {
                await semaphore.wait()
                defer { semaphore.signal() }
                
                count += 1
                effectiveMaxConcurrentRuns = max(effectiveMaxConcurrentRuns, count)
                try? await Task.sleep(for: .milliseconds(100))
                count -= 1
            }
        }
        
        for maxConcurrentRuns in 1...10 {
            let runner = Runner(maxConcurrentRuns: maxConcurrentRuns)
            
            // Spawn many concurrent tasks
            await withTaskGroup(of: Void.self) { group in
                for _ in 0..<20 {
                    group.addTask {
                        await runner.run()
                    }
                }
            }
            
            let effectiveMaxConcurrentRuns = await runner.effectiveMaxConcurrentRuns
            XCTAssertEqual(effectiveMaxConcurrentRuns, maxConcurrentRuns)
        }
    }
    
    func testSemaphoreAsAResourceLimiterOnAsyncMethod() async {
        /// A class that limits the number of concurrent executions of
        /// its `run()` method, and counts the effective number of
        /// concurrent executions for testing purpose.
        @MainActor
        class Runner {
            private let semaphore: AsyncSemaphore
            private var count = 0
            private(set) var effectiveMaxConcurrentRuns = 0
            
            init(maxConcurrentRuns: Int) {
                semaphore = AsyncSemaphore(value: maxConcurrentRuns)
            }
            
            func run() async {
                await semaphore.wait()
                defer { semaphore.signal() }
                
                count += 1
                effectiveMaxConcurrentRuns = max(effectiveMaxConcurrentRuns, count)
                try? await Task.sleep(for: .milliseconds(100))
                count -= 1
            }
        }
        
        for maxConcurrentRuns in 1...10 {
            let runner = await Runner(maxConcurrentRuns: maxConcurrentRuns)
            
            // Spawn many concurrent tasks
            await withTaskGroup(of: Void.self) { group in
                for _ in 0..<20 {
                    group.addTask {
                        await runner.run()
                    }
                }
            }
            
            let effectiveMaxConcurrentRuns = await runner.effectiveMaxConcurrentRuns
            XCTAssertEqual(effectiveMaxConcurrentRuns, maxConcurrentRuns)
        }
    }
    
    func testSemaphoreAsAResourceLimiterOnSingleThread() async {
        /// A class that limits the number of concurrent executions of
        /// its `run()` method, and counts the effective number of
        /// concurrent executions for testing purpose.
        @MainActor
        class Runner {
            private let semaphore: AsyncSemaphore
            private var count = 0
            private(set) var effectiveMaxConcurrentRuns = 0
            
            init(maxConcurrentRuns: Int) {
                semaphore = AsyncSemaphore(value: maxConcurrentRuns)
            }
            
            func run() async {
                await semaphore.wait()
                defer { semaphore.signal() }
                
                count += 1
                effectiveMaxConcurrentRuns = max(effectiveMaxConcurrentRuns, count)
                try? await Task.sleep(for: .milliseconds(100))
                count -= 1
            }
        }
        
        await Task { @MainActor in
            let runner = Runner(maxConcurrentRuns: 3)
            async let x0: Void = runner.run()
            async let x1: Void = runner.run()
            async let x2: Void = runner.run()
            async let x3: Void = runner.run()
            async let x4: Void = runner.run()
            async let x5: Void = runner.run()
            async let x6: Void = runner.run()
            async let x7: Void = runner.run()
            async let x8: Void = runner.run()
            async let x9: Void = runner.run()
            _ = await (x0, x1, x2, x3, x4, x5, x6, x7, x8, x9)
            let effectiveMaxConcurrentRuns = runner.effectiveMaxConcurrentRuns
            XCTAssertEqual(effectiveMaxConcurrentRuns, 3)
        }.value
    }
    
    func testSemaphoreAsAResourceLimiterOnActorMethodWithCancellationSupport() async {
        /// An actor that limits the number of concurrent executions of
        /// its `run()` method, and counts the effective number of
        /// concurrent executions for testing purpose.
        actor Runner {
            private let semaphore: AsyncSemaphore
            private var count = 0
            private(set) var effectiveMaxConcurrentRuns = 0
            
            init(maxConcurrentRuns: Int) {
                semaphore = AsyncSemaphore(value: maxConcurrentRuns)
            }
            
            func run() async throws {
                try await semaphore.waitCheckingCancellation()
                defer { semaphore.signal() }
                
                count += 1
                effectiveMaxConcurrentRuns = max(effectiveMaxConcurrentRuns, count)
                try await Task.sleep(for: .milliseconds(100))
                count -= 1
            }
        }
        
        for maxConcurrentRuns in 1...10 {
            let runner = Runner(maxConcurrentRuns: maxConcurrentRuns)
            
            // Spawn many concurrent tasks
            await withThrowingTaskGroup(of: Void.self) { group in
                for _ in 0..<20 {
                    group.addTask {
                        try await runner.run()
                    }
                }
            }
            
            let effectiveMaxConcurrentRuns = await runner.effectiveMaxConcurrentRuns
            XCTAssertEqual(effectiveMaxConcurrentRuns, maxConcurrentRuns)
        }
    }
}
