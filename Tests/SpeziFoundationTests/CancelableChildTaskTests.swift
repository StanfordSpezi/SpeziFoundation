import SpeziFoundation
import Testing

@Suite("Cancelable Child Task")
struct CancelableChildTaskTests {
    @Test("Normal Completion")
    func testNormalCompletion() async {
        await withDiscardingTaskGroup { group in
            await confirmation { confirmation in
                let handle = group.addCancelableTask {
                    try? await Task.sleep(for: .milliseconds(10), tolerance: .nanoseconds(0))
                    confirmation()
                }

                try? await Task.sleep(for: .milliseconds(20), tolerance: .nanoseconds(0))
                handle.cancel()
            }
        }
    }

    @Test("Cancelation")
    func testCancelation() async {
        await withDiscardingTaskGroup { group in
            await confirmation { confirmation in
                let handle = group.addCancelableTask {
                    do {
                        try await Task.sleep(for: .milliseconds(30), tolerance: .nanoseconds(0))
                        Issue.record("Task was not cancelled!")
                    } catch {
                        confirmation()
                    }
                }

                try? await Task.sleep(for: .milliseconds(5), tolerance: .nanoseconds(0))
                handle.cancel()

                try? await Task.sleep(for: .milliseconds(50), tolerance: .nanoseconds(0))
            }
        }
    }
}
