//
// This source file is part of the Stanford Spezi open-source project
//
// SPDX-FileCopyrightText: 2025 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//


import Dispatch
import SpeziFoundation
import Testing


/// Internal helper actor to be able to have code run guaranteed off the main actor (by scheduling it onto a background queue)
@globalActor
private actor TestActor: GlobalActor {
    final class DispatchQueueExecutor: SerialExecutor {
         private let queue: DispatchQueue

         init(queue: DispatchQueue) {
             self.queue = queue
         }

         func enqueue(_ job: UnownedJob) {
             self.queue.async {
                 job.runSynchronously(on: self.asUnownedSerialExecutor())
             }
         }

         func asUnownedSerialExecutor() -> UnownedSerialExecutor {
             UnownedSerialExecutor(ordinary: self)
         }

        func checkIsolated() {
            dispatchPrecondition(condition: .onQueue(self.queue))
        }
    }
    
    static let shared = TestActor()

    let queue = DispatchQueue(label: "Queue")
    private let executor: DispatchQueueExecutor
    
    nonisolated var unownedExecutor: UnownedSerialExecutor {
        executor.asUnownedSerialExecutor()
    }

    init() {
        self.executor = DispatchQueueExecutor(queue: queue)
    }
}

@Suite
struct MainActorExecutionTests {
    #if os(Linux)
        @Test(.disabled("Skipped on Linux: main thread differs from Darwin"))
    #else
        @Test
    #endif
    @MainActor
    func ifAlreadyRunningOnMainActor() {
        // XCTest by default runs all test cases on the main thread, ie the main queue, ie the main actor.
        dispatchPrecondition(condition: .onQueue(.main))
        var didRun = false
        runOrScheduleOnMainActor {
            didRun = true
        }
        #expect(didRun)
    }
    
    @Test
    @TestActor
    func ifRunningOffTheMainActor() async throws {
        dispatchPrecondition(condition: .notOnQueue(.main))
        dispatchPrecondition(condition: .onQueue(TestActor.shared.queue))
        try await confirmation { confirm in
            runOrScheduleOnMainActor {
                confirm()
            }
            try await Task.sleep(for: .seconds(0.5))
        }
    }
}
