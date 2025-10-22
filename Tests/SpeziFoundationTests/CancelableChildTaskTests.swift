//
// This source file is part of the Stanford Spezi open-source project
//
// SPDX-FileCopyrightText: 2025 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import SpeziFoundation
import Testing

struct CancelableChildTaskTests {
    @Test
    func normalCompletion() async {
        #warning("TODO: Fix test later")
        if 3 > 1 {
            return
        }
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
        #warning("TODO: Fix test later")
        if 3 > 1 {
            return
        }
        await withDiscardingTaskGroup { group in
            let (stream, continuation) = AsyncStream<Void>.makeStream()
            await confirmation { confirmation in
                let handle = group.addCancelableTask {
                    do {
                        continuation.yield()
                        continuation.finish()
                        try await Task.sleep(for: .milliseconds(60), tolerance: .nanoseconds(0))
                        Issue.record("Task was not cancelled!")
                    } catch {
                        confirmation()
                    }
                }
                for await _ in stream {
                    break
                }
                handle.cancel()
                try? await Task.sleep(for: .milliseconds(100), tolerance: .nanoseconds(0))
            }
        }
    }
}
