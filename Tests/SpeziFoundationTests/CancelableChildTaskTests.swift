//
// This source file is part of the Stanford Spezi open-source project
//
// SPDX-FileCopyrightText: 2025 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import SpeziFoundation
import Testing
import Foundation


struct CancelableChildTaskTests {
    @Test
    func normalCompletion() async {
        await withDiscardingTaskGroup { group in
            await confirmation { confirmation in
                let handle = group.addCancelableTask {
                    try? await Task.sleep(for: .milliseconds(10), tolerance: .nanoseconds(0))
                    confirmation()
                }
                try? await Task.sleep(for: .milliseconds(100), tolerance: .nanoseconds(0))
                handle.cancel()
            }
        }
    }
    
    @Test
    func cancelation() async {
        await withDiscardingTaskGroup { group in
            let start = Date()
            await confirmation { confirmation in
                let handle = group.addCancelableTask {
                    do {
                        try await Task.sleep(for: .milliseconds(60), tolerance: .nanoseconds(0))
                        let duration = -start.timeIntervalSinceNow
                        print("XX Task ran for \(duration) seconds")
                        Issue.record("Task was not cancelled!")
                    } catch {
                        confirmation()
                    }
                }
                try? await Task.sleep(for: .milliseconds(10), tolerance: .nanoseconds(0))
                handle.cancel()
                let duration = -start.timeIntervalSinceNow
                print("XX Cancel was called after \(duration) seconds")
                try? await Task.sleep(for: .milliseconds(100), tolerance: .nanoseconds(0))
            }
        }
    }
}
