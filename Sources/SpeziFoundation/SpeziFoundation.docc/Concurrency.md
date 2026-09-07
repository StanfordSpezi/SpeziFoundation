# Concurrency

<!--
#
# This source file is part of the Stanford Spezi open-source project
#
# SPDX-FileCopyrightText: 2026 Stanford University and the project authors (see CONTRIBUTORS.md)
#
# SPDX-License-Identifier: MIT
#
-->

Primitives for coordinating concurrent work: limiting concurrency, bridging callback-based APIs into async/await, and protecting shared state.

## Overview

Swift's structured concurrency covers a lot of ground, but a few needs that come up regularly in Spezi modules are not directly served by the standard library:
capping how many operations run at once, waiting for a delegate-based API to report back, or guarding a mutable value that is accessed from arbitrary threads.
SpeziFoundation provides a small set of primitives for these situations. This article describes when to reach for which one; the individual symbols document the details.

| Need | Use |
| --- | --- |
| Limit concurrent access to a resource from otherwise unrelated tasks | ``AsyncSemaphore`` |
| Run a dynamic number of independent operations, at most N at a time | ``withManagedTaskQueue(limit:_:)`` |
| Await a callback-based operation, allowing only one at a time | ``ManagedAsynchronousAccess`` |
| Protect shared mutable state accessed from multiple threads, synchronously | ``RWLock``, ``RecursiveRWLock`` |
| Cancel an individual child task of a `DiscardingTaskGroup` | ``_Concurrency/DiscardingTaskGroup/addCancelableTask(_:)`` |
| Bound the time an operation may take | ``withTimeout(of:perform:)`` |

### Limiting Concurrency with AsyncSemaphore

``AsyncSemaphore`` is a counting semaphore for async code: a task that calls one of its `wait` functions while the semaphore's count is exhausted is *suspended*
rather than blocking its thread, and resumed once another task calls ``AsyncSemaphore/signal()``.

The two wait variants differ in how they treat cancellation. ``AsyncSemaphore/waitCheckingCancellation()`` throws a `CancellationError` if the waiting task is cancelled before it acquires the semaphore,
which is what you want for anything user-initiated. ``AsyncSemaphore/wait()`` cannot be interrupted, and should be reserved for work that must run regardless.
In both cases, pair the wait with a `signal()` call, ideally via `defer`:

```swift
final class UploadClient: Sendable {
    // Allow at most three uploads to be in flight at any given time.
    private let semaphore = AsyncSemaphore(value: 3)

    func upload(_ data: Data) async throws {
        try await semaphore.waitCheckingCancellation()
        defer { semaphore.signal() }
        try await performUpload(data)
    }
}
```

The semaphore isn't tied to any task tree, which makes it the right tool when the callers are unrelated tasks, e.g., SwiftUI actions, background refreshes, and incoming requests all competing for the same resource.
Created with its default `value` of 1, it acts as an async-aware mutex.
When the full set of work is known up front, prefer ``withManagedTaskQueue(limit:_:)``, which does the bookkeeping for you.

- Note: ``AsyncSemaphore/cancelAll()`` resumes every waiting task by throwing a `CancellationError`, and traps if any of them is waiting via the non-cancellable `wait()`.
    Avoid mixing the two wait variants on a semaphore you intend to cancel.

Within the Spezi ecosystem, `SpeziLLM` uses an `AsyncSemaphore` to bound the number of concurrent inference jobs, and `Spezi` itself uses one to serialize remote notification registration requests.

### Bounded Parallelism with withManagedTaskQueue

``withManagedTaskQueue(limit:_:)`` runs a dynamic number of independent operations while ensuring that no more than `limit` of them execute at the same time,
and returns once all of them have completed. Operations are submitted through the ``ManagedTaskQueue`` that is passed to the body closure.
Since the body is itself asynchronous, operations can also be added while iterating an `AsyncSequence`:

```swift
func export(_ batches: [ExportBatch], to destination: Destination) async {
    await withManagedTaskQueue(limit: 4) { taskQueue in
        for batch in batches {
            taskQueue.addTask {
                let data = await batch.collectSamples()
                await destination.write(data)
            }
        }
    }
    // All batches have been processed at this point.
}
```

Compared to a plain `withTaskGroup`, which starts every child task immediately, this saves you from manually interleaving `addTask` and `next()` calls to keep the number of in-flight tasks bounded.
Operations cannot throw or return values; if you need results, collect them through an actor or an `AsyncStream`.

`SpeziHealthKit`'s bulk exporter uses a managed task queue to process export batches with a user-configurable concurrency level.

### Bridging Callback APIs with ManagedAsynchronousAccess

Many system frameworks (CoreBluetooth, for example) start an operation imperatively and report its result through a delegate callback,
and only allow a single such operation to be in flight at a time. ``ManagedAsynchronousAccess`` turns this pattern into a single `async` call:
``ManagedAsynchronousAccess/perform(isolation:action:)-7rqia`` waits for exclusive access, runs the `action` closure to kick off the operation, and then suspends until the delegate callback
calls ``ManagedAsynchronousAccess/resume(returning:)``, ``ManagedAsynchronousAccess/resume(throwing:)``, or ``ManagedAsynchronousAccess/resume(with:)``.
Resuming also hands the access over to the next waiting caller, if any.

```swift
@MainActor
final class DevicePairing: DevicePairingDelegate {
    private let device: Device
    private let pairingAccess = ManagedAsynchronousAccess<Void, any Error>()

    func pair() async throws {
        try await pairingAccess.perform {
            device.startPairing(delegate: self) // reports back via the delegate methods below
        }
    }

    func pairingDidSucceed(_ device: Device) {
        pairingAccess.resume()
    }

    func pairing(_ device: Device, didFailWith error: any Error) {
        pairingAccess.resume(throwing: error)
    }
}
```

`ManagedAsynchronousAccess` performs no internal synchronization of its own; call `perform` and `resume` from the same isolation domain, e.g., the actor that also receives the delegate callbacks.
`SpeziBluetooth` uses one instance per peripheral operation (connect, disconnect, RSSI reads, service discovery) to expose CoreBluetooth's delegate-based API as async functions.

### Protecting Shared State with Read-Write Locks

Actors are the preferred way to protect mutable state in Swift, but they require every access to be asynchronous.
Where that isn't possible, e.g. in synchronous property accessors, delegate callbacks, or `@unchecked Sendable` wrapper types, ``RWLock`` offers a lightweight `pthread_rwlock`-based lock.
Use ``RWLock/withReadLock(_:)`` for read-only accesses and ``RWLock/withWriteLock(_:)`` for mutations; both return the closure's result and forward its (typed) error:

```swift
final class SampleCache: @unchecked Sendable {
    private let lock = RWLock()
    private var storage: [SampleType: [Sample]] = [:]

    func samples(for type: SampleType) -> [Sample] {
        lock.withReadLock { storage[type] ?? [] }
    }

    func store(_ samples: [Sample], for type: SampleType) {
        lock.withWriteLock { storage[type] = samples }
    }
}
```

Never call `await` while holding the lock, and don't acquire an `RWLock` again from within one of its closures: `pthread_rwlock` is not re-entrant.
If a thread holding the write lock needs to lock again (e.g., because a `withWriteLock` body calls a function that also takes the lock), use ``RecursiveRWLock`` instead.

`SpeziBluetooth`, `SpeziLLM`, `SpeziHealthKit`, and `SpeziStorage` all rely on these locks to protect state that is accessed from both Swift concurrency and callback-based APIs.

### Cancelling Individual Child Tasks

A `DiscardingTaskGroup` only offers `cancelAll()`; there is no way to cancel a single child task.
``_Concurrency/DiscardingTaskGroup/addCancelableTask(_:)`` closes this gap by returning a ``CancelableTaskHandle`` for the task it adds.
Cancellation is cooperative, just like with any other task: the operation needs to check `Task.isCancelled` or call an API that does.

```swift
await withDiscardingTaskGroup { group in
    var handles: [Module.ID: CancelableTaskHandle] = [:]
    for module in modules {
        handles[module.id] = group.addCancelableTask { await module.run() }
    }
    for await event in lifecycleEvents {
        if case .unload(let id) = event {
            handles[id]?.cancel()
        }
    }
}
```

`Spezi` uses this to stop the long-running task of an individual service module when that module is cancelled, without affecting the other service modules.

### Timeouts

``withTimeout(of:perform:)`` races an operation against a timeout. Refer to its documentation for the recommended usage pattern within structured concurrency.

## Topics

### Semaphore

- ``AsyncSemaphore``

### Managed Task Queue

- ``withManagedTaskQueue(limit:_:)``
- ``ManagedTaskQueue``

### Managed Asynchronous Access

- ``ManagedAsynchronousAccess``

### Read-Write Locks

- ``RWLock``
- ``RecursiveRWLock``

### Cancelable Child Tasks

- ``_Concurrency/DiscardingTaskGroup/addCancelableTask(_:)``
- ``CancelableTaskHandle``

### Type Erasure

- ``AnyAsyncSequence``
- ``AnyAsyncIterator``

### Deprecated

- ``runOrScheduleOnMainActor(_:)``
