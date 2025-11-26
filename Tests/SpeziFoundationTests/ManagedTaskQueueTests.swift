//
// This source file is part of the Stanford Spezi open-source project
//
// SPDX-FileCopyrightText: 2025 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

// swiftlint:disable force_try

import Foundation
import SpeziFoundation
import Testing


@Suite
struct ManagedTaskQueueTests {
    @MainActor
    private final class OperationsTracker: Sendable {
        let expectedLimit: Int
        private(set) var active = Set<Int>()
        private(set) var completed = Set<Int>()
        private(set) var maxObservedConcurrency = 0
        
        nonisolated init(expectedLimit: Int) {
            self.expectedLimit = expectedLimit
        }
        
        func trackBegin(of operation: Int) throws {
            #expect(
                active.count < expectedLimit,
                "adding \(operation); active: \(active.sorted()); completed: \(completed.sorted())"
            )
            try #require(!completed.contains(operation), "Operation '\(operation)' has already run")
            try #require(active.insert(operation).inserted, "Operation '\(operation)' is already running")
            maxObservedConcurrency = max(maxObservedConcurrency, active.count)
        }
        
        func trackEnd(of operation: Int) throws {
            #expect(
                active.count <= expectedLimit,
                "removing \(operation); active: \(active.sorted()); completed: \(completed.sorted())"
            )
            try #require(!completed.contains(operation), "Operation '\(operation)' has already run")
            let idx = try #require(active.firstIndex(of: operation), "Operation '\(operation)' is not running")
            active.remove(at: idx)
            completed.insert(operation)
        }
    }
    
    
    @Test(arguments: Array(1...17))
    func managedTaskQueue4(concurrencyLimit: Int) async {
        let numTasks = concurrencyLimit * 3
        let tracker = OperationsTracker(expectedLimit: concurrencyLimit)
        await withManagedTaskQueue(limit: concurrencyLimit) { taskQueue in
            for idx in 0..<numTasks {
                taskQueue.addTask {
                    try! await tracker.trackBegin(of: idx)
                    sleep(for: .seconds(0.25))
                    try! await tracker.trackEnd(of: idx)
                }
            }
        }
        #expect(await tracker.active.isEmpty)
        #expect(await tracker.completed == Set(0..<numTasks))
        #expect(await tracker.maxObservedConcurrency <= concurrencyLimit)
        await print("max observed concurrency for limit=\(concurrencyLimit): \(tracker.maxObservedConcurrency)")
    }
}


func sleep(for duration: Duration) {
    usleep(UInt32(duration.timeInterval * 1000000))
}
