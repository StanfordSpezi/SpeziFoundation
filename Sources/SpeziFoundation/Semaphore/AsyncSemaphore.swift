//
// This source file is part of the Stanford Spezi open-source project
//
// SPDX-FileCopyrightText: 2024 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import Foundation


/// Asynchronous semaphore for coordinating the concurrent execution of tasks.
///
/// ``AsyncSemaphore`` provides a mechanism to regulate access to a resource that allows multiple accesses up to a certain limit.
/// Beyond this limit, tasks must wait until the semaphore signals that access is available. It supports both cancellable and non-cancellable waits,
/// enabling tasks to either proceed when the semaphore is available or throw a `CancellationError` if the task was cancelled while waiting.
///
/// - Note: This semaphore uses Foundation's `NSLock` for thread safety and handles task suspension and resumption internally.
///
/// ### Usage
///
/// Initialize ``AsyncSemaphore`` with the maximum number of concurrent accesses allowed:
/// ```
/// let semaphore = AsyncSemaphore(value: 3)
/// ```
///
/// To wait for access (blocking the task until access is available):
/// ```
/// await semaphore.wait()
/// ```
///
/// To wait for access but track cancellations (leading to the throwing of a `CancellationError`):
/// ```
/// try await semaphore.waitCheckingCancellation()
/// ```
///
/// To signal that a task has completed its access, potentially allowing waiting tasks to proceed:
/// ```
/// semaphore.signal()
/// ```
///
/// To signal all waiting tasks to proceed:
/// ```
/// semaphore.signalAll()
/// ```
///
/// To cancel all waiting tasks (only those that support cancellation):
/// ```
/// semaphore.cancelAll()
/// ```
///
/// - Warning: `cancelAll` will trigger a runtime error if it attempts to cancel tasks that are not cancellable.
public final class AsyncSemaphore: @unchecked Sendable {
    private enum Suspension {
        case cancelable(UnsafeContinuation<Void, Error>)
        case regular(UnsafeContinuation<Void, Never>)

        
        func resume() {
            switch self {
            case let .regular(continuation):
                continuation.resume()
            case let .cancelable(continuation):
                continuation.resume()
            }
        }
    }
    
    private struct SuspendedTask: Identifiable {
        let id: UUID
        let suspension: Suspension
    }

    
    private var value: Int
    private var suspendedTasks: [SuspendedTask] = []
    private let nsLock = NSLock()

    
    /// Initializes a new semaphore with a given concurrency limit.
    ///
    /// - Parameter value: The maximum number of concurrent accesses allowed. Must be non-negative.
    public init(value: Int = 1) {
        precondition(value >= 0)
        self.value = value
    }


    /// Decreases the semaphore count and waits if the count is less than zero.
    ///
    /// Use this method when access to a resource should be awaited without the possibility of cancellation.
    public func wait() async {
        lock()

        value -= 1
        if value >= 0 {
            unlock()
            return
        }

        await withUnsafeContinuation { continuation in
            suspendedTasks.append(SuspendedTask(id: UUID(), suspension: .regular(continuation)))
            unlock()
        }
    }

    /// Decreases the semaphore count and throws a `CancellationError` if the current `Task` is cancelled.
    ///
    /// This method allows the `Task` calling ``waitCheckingCancellation()`` to be cancelled while waiting, throwing a `CancellationError` if the `Task` is cancelled before it can proceed.
    ///
    /// - Throws: `CancellationError` if the task is cancelled while waiting.
    public func waitCheckingCancellation() async throws {
        try Task.checkCancellation() // check if we are already cancelled

        lock()

        do {
            // check if we got cancelled while acquiring the lock
            try Task.checkCancellation()
        } catch {
            unlock()
            throw error
        }

        value -= 1 // decrease the value
        if value >= 0 {
            unlock()
            return
        }

        let id = UUID()

        try await withTaskCancellationHandler {
            try await withUnsafeThrowingContinuation { (continuation: UnsafeContinuation<Void, Error>) in
                if Task.isCancelled {
                    value += 1 // restore the value
                    unlock()

                    continuation.resume(throwing: CancellationError())
                } else {
                    suspendedTasks.append(SuspendedTask(id: id, suspension: .cancelable(continuation)))
                    unlock()
                }
            }
        } onCancel: {
            self.lock()
            
            value += 1
            
            guard let index = suspendedTasks.firstIndex(where: { $0.id == id }) else {
                preconditionFailure("Inconsistent internal state reached")
            }
            
            let task = suspendedTasks[index]
            suspendedTasks.remove(at: index)
            
            unlock()
            
            switch task.suspension {
            case .regular:
                preconditionFailure("Tried to cancel a task that was not cancellable!")
            case let .cancelable(continuation):
                continuation.resume(throwing: CancellationError())
            }
        }
    }


    /// Signals the semaphore, allowing one waiting task to proceed.
    ///
    /// If there are `Task`s waiting for access, calling this method will resume one of them.
    ///
    /// - Returns: `true` if a task was resumed, `false` otherwise.
    @discardableResult
    public func signal() -> Bool {
        lock()

        value += 1

        guard let first = suspendedTasks.first else {
            unlock()
            return false
        }

        suspendedTasks.removeFirst()
        unlock()

        first.suspension.resume()
        return true
    }

    /// Signals the semaphore, allowing all waiting `Task`s to proceed.
    ///
    /// This method resumes all `Task`s that are currently waiting for access.
    public func signalAll() {
        lock()

        value += suspendedTasks.count

        let tasks = suspendedTasks
        self.suspendedTasks.removeAll()

        unlock()

        for task in tasks {
            task.suspension.resume()
        }
    }

    /// Cancels all waiting `Task`s that can be cancelled.
    ///
    /// This method attempts to cancel all `Task`s that are currently waiting and support cancellation. `Task`s that do not support cancellation will cause a runtime error.
    ///
    /// - Warning: Will trigger a runtime error if it attempts to cancel `Task`s that are not cancellable.
    public func cancelAll() {
        lock()

        value += suspendedTasks.count

        let tasks = suspendedTasks
        self.suspendedTasks.removeAll()

        unlock()

        for task in tasks {
            switch task.suspension {
            case .regular:
                preconditionFailure("Tried to cancel a task that was not cancellable!")
            case let .cancelable(continuation):
                continuation.resume(throwing: CancellationError())
            }
        }
    }
    
    private func lock() {
        nsLock.lock()
    }

    private func unlock() {
        nsLock.unlock()
    }
}
