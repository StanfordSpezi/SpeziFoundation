//
// This source file is part of the Stanford Spezi open-source project
//
// SPDX-FileCopyrightText: 2024 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//
// Tests adopted from https://github.com/groue/Semaphore/blob/main/Sources/Semaphore/AsyncSemaphore.swift.
//

import Foundation
@testable import SpeziFoundation
import Testing

@Suite("Async Semaphore Tests")
final class AsyncSemaphoreTests {   // swiftlint:disable:this type_body_length
    @Test
    func testSignalWithoutSuspendedTasks() {
        let dispatchSemZero = DispatchSemaphore(value: 0)
        #expect(dispatchSemZero.signal() == 0)
        
        let dispatchSemOne = DispatchSemaphore(value: 1)
        #expect(dispatchSemOne.signal() == 0)
        
        let dispatchSemTwo = DispatchSemaphore(value: 2)
        #expect(dispatchSemTwo.signal() == 0)

        let asyncSemZero = AsyncSemaphore(value: 0)
        let wokenZero = asyncSemZero.signal()
        #expect(!wokenZero)
        
        let asyncSemOne = AsyncSemaphore(value: 1)
        let wokenOne = asyncSemOne.signal()
        #expect(!wokenOne)
        
        let asyncSemTwo = AsyncSemaphore(value: 2)
        let wokenTwo = asyncSemTwo.signal()
        #expect(!wokenTwo)
    }
    
    @Test
    func testSignalReturnsWhetherItResumesSuspendedTask() async throws {
        let delay: Duration = .milliseconds(500)
        
        // Check DispatchSemaphore behavior
        do {
            // Given a thread waiting for the semaphore
            let sem = DispatchSemaphore(value: 0)
            Thread { sem.wait() }.start()
            try await Task.sleep(for: delay)
            
            // First signal wakes the waiting thread
            #expect(sem.signal() != 0)
            // Second signal does not wake any thread
            #expect(sem.signal() == 0)
        }
        
        // Test that AsyncSemaphore behaves identically
        do {
            // Given a task suspended on the semaphore
            let sem = AsyncSemaphore(value: 0)
            Task { await sem.wait() }
            try await Task.sleep(for: delay)
            
            // First signal resumes the suspended task
            #expect(sem.signal())
            // Second signal does not resume any task
            #expect(!sem.signal())
        }
    }
    
    @Test
    func testWaitSuspendsOnZeroSemaphoreUntilSignal() async throws {
        let waitTime: Duration = .milliseconds(100)

        // Check DispatchSemaphore behavior
        let dispatchSemaphore = DispatchSemaphore(value: 0)

        try await confirmation("thread woken") { woken in
            let startTime = ContinuousClock.now
            
            Thread {
                // When a thread waits for this semaphore,
                dispatchSemaphore.wait()
                // The following part should only run after the thread is woken: after the waitTime
                #expect(ContinuousClock.now >= startTime + waitTime, "Thread should only run after semaphore is signalled")
                woken()
            }.start()
            
            // Give the thread time to block
            try await Task.sleep(for: waitTime)
            // Wake the thread
            dispatchSemaphore.signal()
            // Let it run before we exit the scope
            try await Task.sleep(for: .milliseconds(10))
        }


        // Test that AsyncSemaphore behaves identically
        let asyncSemaphore = AsyncSemaphore(value: 0)
        
        try await confirmation("task woken") { woken in
            let startTime = ContinuousClock.now
            
            Task {
                // When a thread waits for this semaphore,
                await asyncSemaphore.wait()
                // The following part should only run after the thread is woken: after the waitTime
                #expect(ContinuousClock.now >= startTime + waitTime, "Task should only continue after semaphore is signalled")
                woken()
            }
            
            // Give the task time to block
            try await Task.sleep(for: waitTime)
            // Resume the task
            asyncSemaphore.signal()
            // Let it run before we exit the scope
            try await Task.sleep(for: .milliseconds(10))
        }
    }
    
    @Test
    func testCancellationWhileSuspendedThrowsCancellationError() async throws {
        let sem = AsyncSemaphore(value: 0)
        
        try await confirmation("cancellation") { confirm in
            let task = Task {
                do {
                    try await sem.waitCheckingCancellation()
                    Issue.record("Expected CancellationError")
                } catch is CancellationError {
                    confirm()
                } catch {
                    Issue.record("Unexpected error")
                }
            }
            
            try await Task.sleep(for: .milliseconds(100))
            task.cancel()
            await task.value
        }
    }

    @Test
    func testCancellationBeforeSuspensionThrowsCancellationError() async throws {
        let sem = AsyncSemaphore(value: 0)
        
        await confirmation("cancellation") { confirm in
            let task = Task {
                // Uncancellable delay
                await withUnsafeContinuation { continuation in
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        continuation.resume()
                    }
                }

                do {
                    try await sem.waitCheckingCancellation()
                    Issue.record("Expected CancellationError")
                } catch is CancellationError {
                    confirm()
                } catch {
                    Issue.record("Unexpected error")
                }
            }
            
            task.cancel()
            await task.value
        }
    }


    @Test
    func testCancellationWhileSuspendedIncrementsSemaphore() async throws {
        let waitTime: Duration = .milliseconds(100)

        // Given a task cancelled while suspended on a semaphore,
        let sem = AsyncSemaphore(value: 0)

        let task = Task {
            try await sem.waitCheckingCancellation()
        }
        try await Task.sleep(for: .milliseconds(100))
        task.cancel()
        
        // When a task waits for this semaphore,
        try await confirmation("task woken") { woken in
            let startTime = ContinuousClock.now

            let task = Task {
                await sem.wait() // Then the task is initially suspended.
                #expect(ContinuousClock.now >= startTime + waitTime, "Task should only continue after semaphore is signalled")
                woken()
            }
            
            try await Task.sleep(for: .milliseconds(100))
            // When a signal occurs, then the suspended task is resumed.
            sem.signal()

            await task.value
        }
    }

    
    @Test
    func testCancellationBeforeSuspensionIncrementsSemaphore() async throws {
        let waitTime: Duration = .milliseconds(100)
        
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
        try await confirmation("task woken") { woken in
            let startTime = ContinuousClock.now
            
            let task = Task {
                await sem.wait()
                #expect(ContinuousClock.now >= startTime + waitTime, "Task should only continue after semaphore is signalled")
                woken()
            }
            
            // Then the task is initially suspended.
            try await Task.sleep(for: .milliseconds(100))
            
            // When a signal occurs, then the suspended task is resumed.
            sem.signal()
            await task.value
        }
    }
    
    
    @Test
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
            #expect(effectiveMaxConcurrentRuns == maxConcurrentRuns)
        }
    }
    
    @Test
    func testSemaphoreAsAResourceLimiterOnAsyncMethod() async {
        /// A class that limits the number of concurrent executions of
        /// its `run()` method, and counts the effective number of
        /// concurrent executions for testing purpose.
        @MainActor
        final class Runner {
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
            #expect(effectiveMaxConcurrentRuns == maxConcurrentRuns)
        }
    }
    
    @Test
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
            async let run0: Void = runner.run()
            async let run1: Void = runner.run()
            async let run2: Void = runner.run()
            async let run3: Void = runner.run()
            async let run4: Void = runner.run()
            async let run5: Void = runner.run()
            async let run6: Void = runner.run()
            async let run7: Void = runner.run()
            async let run8: Void = runner.run()
            async let run9: Void = runner.run()
            _ = await (run0, run1, run2, run3, run4, run5, run6, run7, run8, run9)
            let effectiveMaxConcurrentRuns = runner.effectiveMaxConcurrentRuns
            #expect(effectiveMaxConcurrentRuns == 3)
        }.value
    }
    
    @Test
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
            #expect(effectiveMaxConcurrentRuns == maxConcurrentRuns)
        }
    }
}
