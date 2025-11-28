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
        struct Operation: Hashable {
            let id: Int
            let startDate: Date
            let endDate: Date
            
            var timeRange: Range<Date> {
                startDate..<endDate
            }
            
            static func == (lhs: Self, rhs: Self) -> Bool {
                lhs.id == rhs.id
            }
            func hash(into hasher: inout Hasher) {
                hasher.combine(id)
            }
        }
        
        let expectedLimit: Int
        private(set) var active = Set<Operation>()
        private(set) var completed = Set<Operation>()
        private(set) var maxObservedConcurrency = 0
        
        var activeIds: Set<Int> {
            active.mapIntoSet(\.id)
        }
        var completedIds: Set<Int> {
            completed.mapIntoSet(\.id)
        }
        
        nonisolated init(expectedLimit: Int) {
            self.expectedLimit = expectedLimit
        }
        
        func trackBegin(of operationId: Int) throws {
            #expect(
                active.count < expectedLimit,
                "adding \(operationId); active: \(activeIds.sorted()); completed: \(completedIds.sorted())"
            )
            try #require(!completed.contains { $0.id == operationId }, "Operation '\(operationId)' has already run")
            try #require(active.insert(.init(id: operationId, startDate: .now, endDate: .distantFuture)).inserted, "Operation '\(operationId)' is already running")
            maxObservedConcurrency = max(maxObservedConcurrency, active.count)
        }
        
        func trackEnd(of operationId: Int) throws {
            #expect(
                active.count <= expectedLimit,
                "removing \(operationId); active: \(activeIds.sorted()); completed: \(completedIds.sorted())"
            )
            try #require(!completed.contains { $0.id == operationId }, "Operation '\(operationId)' has already run")
            let idx = try #require(active.firstIndex { $0.id == operationId }, "Operation '\(operationId)' is not running")
            let operation = active.remove(at: idx)
            completed.insert(.init(id: operation.id, startDate: operation.startDate, endDate: .now))
        }
    }
    
    
    @Test(arguments: Array(1...17))
    func managedTaskQueue(concurrencyLimit: Int) async {
        let numTasks = concurrencyLimit * 3
        let tracker = OperationsTracker(expectedLimit: concurrencyLimit)
        await withManagedTaskQueue(limit: concurrencyLimit) { taskQueue in
            for idx in 0..<numTasks {
                taskQueue.addTask {
                    try! await tracker.trackBegin(of: idx)
                    try! await Task.sleep(for: .seconds(0.25))
                    try! await tracker.trackEnd(of: idx)
                }
            }
        }
        #expect(await tracker.active.isEmpty)
        #expect(await tracker.completedIds == Set(0..<numTasks))
        #expect(await tracker.maxObservedConcurrency <= concurrencyLimit)
    }
    
    
    @Test(arguments: [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20])
    func ordering(concurrencyLimit: Int) async throws {
        let start = Date.now
        let tracker = OperationsTracker(expectedLimit: concurrencyLimit)
        await withManagedTaskQueue(limit: concurrencyLimit) { taskQueue in
            for idx in 0..<(concurrencyLimit * 3) {
                taskQueue.addTask {
                    try! await tracker.trackBegin(of: idx)
                    try! await Task.sleep(for: .seconds(2))
                    try! await tracker.trackEnd(of: idx)
                }
            }
        }
        let end = Date.now
        for timestamp in stride(from: start.addingTimeInterval(0.1), through: end.addingTimeInterval(-2.5), by: 0.5) {
            let numActiveTasks = await tracker.completed.count { $0.timeRange.contains(timestamp) }
            #expect(numActiveTasks == concurrencyLimit, "FAILED for offset \(timestamp.timeIntervalSince(start))")
        }
    }
}
