<!--
This source file is part of the Stanford Spezi open-source project

SPDX-FileCopyrightText: 2026 Stanford University and the project authors (see CONTRIBUTORS.md)

SPDX-License-Identifier: MIT
-->

# Concurrency

Synchronization primitives for coordinating concurrent work in Swift 6 async/await contexts and beyond.

## Overview

SpeziFoundation provides three complementary concurrency primitives that cover the most common synchronization needs: rate-limiting async tasks, running a bounded batch of concurrent operations, and protecting shared mutable state with a classic reader-writer lock.

### AsyncSemaphore

``AsyncSemaphore`` is an async/await–native semaphore. It maintains an internal counter representing the number of additional concurrent accesses permitted. When a task calls ``AsyncSemaphore/wait()`` or ``AsyncSemaphore/waitCheckingCancellation()`` and the counter has been exhausted, the task suspends without blocking a thread. Once another task calls ``AsyncSemaphore/signal()``, one of the suspended tasks resumes.

Use ``AsyncSemaphore/waitCheckingCancellation()`` when the surrounding `Task` should be cancellable while it waits; use ``AsyncSemaphore/wait()`` when cancellation should not interrupt the wait.

```swift
// Allow at most 3 simultaneous network requests.
let semaphore = AsyncSemaphore(value: 3)

func fetchResource(_ url: URL) async throws -> Data {
    try await semaphore.waitCheckingCancellation()
    defer { semaphore.signal() }
    let (data, _) = try await URLSession.shared.data(from: url)
    return data
}

func fetchAll(urls: [URL]) async throws -> [Data] {
    try await withThrowingTaskGroup(of: Data.self) { group in
        for url in urls {
            group.addTask { try await fetchResource(url) }
        }
        return try await group.reduce(into: []) { $0.append($1) }
    }
}
```

### withManagedTaskQueue

``withManagedTaskQueue(limit:_:)`` runs a dynamic collection of child tasks while capping the number that execute concurrently. Tasks are submitted through the ``ManagedTaskQueue`` value passed to the body closure. The function returns only after every submitted task has finished.

This is the preferred pattern when the full set of work items is known up front and each item is independent, such as bulk uploads or batch processing pipelines.

```swift
// Process sensor readings in parallel, but no more than 4 at a time.
func uploadNewData(for sensors: [Sensor]) async {
    await withManagedTaskQueue(limit: 4) { queue in
        for sensor in sensors {
            queue.addTask {
                let data = await sensor.fetchLatestReading()
                await uploadToServer(data)
            }
        }
    }
}
```

### RWLock

``RWLock`` is a thin, high-performance wrapper around `pthread_rwlock_t`. It is suitable for protecting shared mutable state that is read often but written rarely — multiple readers can hold the lock simultaneously, while a writer gets exclusive access.

Use ``RWLock/withReadLock(_:)`` for read-only access and ``RWLock/withWriteLock(_:)`` for mutation. Because `RWLock` is synchronous (non-async), it is safe to use inside actors, on the main thread, or anywhere a blocking lock is acceptable. For recursive locking scenarios, use ``RecursiveRWLock`` instead.

```swift
final class Cache<Key: Hashable, Value>: @unchecked Sendable {
    private var storage: [Key: Value] = [:]
    private let lock = RWLock()

    func value(for key: Key) -> Value? {
        lock.withReadLock { storage[key] }
    }

    func setValue(_ value: Value, for key: Key) {
        lock.withWriteLock { storage[key] = value }
    }
}
```

## Topics

### Async Semaphore

- ``AsyncSemaphore``

### Managed Task Queue

- ``withManagedTaskQueue(limit:_:)``
- ``ManagedTaskQueue``
- ``ManagedAsynchronousAccess``
- ``CancelableTaskHandle``

### Reader-Writer Locks

- ``RWLock``
- ``RecursiveRWLock``

### Other

- ``runOrScheduleOnMainActor(_:)``
- ``_Concurrency/DiscardingTaskGroup/addCancelableTask(_:)``
