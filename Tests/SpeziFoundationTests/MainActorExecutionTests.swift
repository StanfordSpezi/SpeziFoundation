//
// This source file is part of the Stanford Spezi open-source project
//
// SPDX-FileCopyrightText: 2025 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//


import Dispatch
@testable import SpeziFoundation
import Testing
import Foundation

/// Internal helper actor to be able to have code run guaranteed off the main actor (by scheduling it onto a background queue)
@globalActor
private actor TestActor: GlobalActor {
    static let shared = TestActor()
    let queue = DispatchQueue(label: "Queue")
    private let executor: DispatchQueueExecutor
    
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
    
    nonisolated public var unownedExecutor: UnownedSerialExecutor {
        executor.asUnownedSerialExecutor()
    }

    init() {
        self.executor = DispatchQueueExecutor(queue: queue)
    }
}

struct MainActorExecutionTests {
    @MainActor
    @Test(.disabled(if: isLinux, "Skipped on Linux: main thread differs from Darwin"))
    func testIfAlreadyRunningOnMainActor() {
        precondition(#isolation === MainActor.shared)
        dispatchPrecondition(condition: .onQueue(.main))
        var didRun = false
        runOrScheduleOnMainActor {
            didRun = true
        }
        #expect(didRun)
    }
    

    @TestActor
    @Test
    func testIfRunningOffTheMainActor() async {
        dispatchPrecondition(condition: .notOnQueue(.main))
        dispatchPrecondition(condition: .onQueue(TestActor.shared.queue))
        #expect(#isolation === TestActor.shared)

        await confirmation("ran off the main actor") { didRun in
            runOrScheduleOnMainActor {
                didRun()
                #expect(#isolation === MainActor.shared)
            }

            try? await Task.sleep(for: .milliseconds(5), tolerance: .nanoseconds(0))
        }
    }
}
