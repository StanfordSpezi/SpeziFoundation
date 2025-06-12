//
// This source file is part of the Stanford Spezi open-source project
//
// SPDX-FileCopyrightText: 2024 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

#if !os(Linux)

import Atomics
import Foundation


/// Recursive Read-Write Lock using `pthread_rwlock`.
///
/// This is a recursive version of the ``RWLock`` implementation.
public final class RecursiveRWLock: PThreadReadWriteLock, @unchecked Sendable {
    let rwLock: UnsafeMutablePointer<pthread_rwlock_t>

    private let writerThread = ManagedAtomic<pthread_t?>(nil)
    private var writerCount = 0
    private var readerCount = 0

    /// Create a new recursive read-write lock.
    public init() {
        rwLock = Self.pthreadInit()
    }


    private func writeLock() {
        let selfThread = pthread_self()

        if let writer = writerThread.load(ordering: .relaxed),
           pthread_equal(writer, selfThread) != 0 {
            // we know that the writerThread is us, so access to `writerCount` is synchronized (its us that holds the rwLock).
            writerCount += 1
            assert(writerCount > 1, "Synchronization issue. Writer count is unexpectedly low: \(writerCount)")
            return
        }

        pthreadWriteLock()

        writerThread.store(selfThread, ordering: .relaxed)
        writerCount = 1
    }

    private func writeUnlock() {
        // we assume this is called while holding the write lock, so access to `writerCount` is safe
        if writerCount > 1 {
            writerCount -= 1
            return
        }

        // otherwise it is the last unlock
        writerThread.store(nil, ordering: .relaxed)
        writerCount = 0

        pthreadUnlock()
    }

    private func readLock() {
        let selfThread = pthread_self()

        if let writer = writerThread.load(ordering: .relaxed),
           pthread_equal(writer, selfThread) != 0 {
            // we know that the writerThread is us, so access to `readerCount` is synchronized (its us that holds the rwLock).
            readerCount += 1
            assert(readerCount > 0, "Synchronization issue. Reader count is unexpectedly low: \(readerCount)")
            return
        }

        pthreadReadLock()
    }

    private func readUnlock() {
        // we assume this is called while holding the reader lock, so access to `readerCount` is safe
        if readerCount > 0 {
            // fine to go down to zero (we still hold the lock in write mode)
            readerCount -= 1
            return
        }

        pthreadUnlock()
    }


    /// Call `body` with a writing lock.
    ///
    /// - Parameter body: A function that writes a value while locked, then returns some value.
    /// - Returns: The value returned from the given function.
    public func withWriteLock<T>(body: () throws -> T) rethrows -> T {
        writeLock()
        defer {
            writeUnlock()
        }
        return try body()
    }

    /// Call `body` with a reading lock.
    ///
    /// - Parameter body: A function that reads a value while locked.
    /// - Returns: The value returned from the given function.
    public func withReadLock<T>(body: () throws -> T) rethrows -> T {
        readLock()
        defer {
            readUnlock()
        }
        return try body()
    }

    deinit {
        pthreadDeinit()
    }
}

#endif
