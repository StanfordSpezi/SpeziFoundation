//
// This source file is part of the Stanford Spezi open-source project
//
// SPDX-FileCopyrightText: 2024 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//


import Foundation
#if canImport(Glibc)
import Glibc
#endif

protocol PThreadReadWriteLock: AnyObject {
    // We need the unsafe mutable pointer, as otherwise we need to pass the property as inout parameter which isn't thread safe.
    var rwLock: UnsafeMutablePointer<pthread_rwlock_t> { get }
}


/// Read-Write Lock using `pthread_rwlock`.
///
/// Looking at [Benchmarking Swift Locking APIs](https://www.vadimbulavin.com/benchmarking-locking-apis), using `pthread_rwlock`
/// is favorable over using dispatch queues.
///
/// - Note: Refer to ``RecursiveRWLock`` if you need a recursive read-write lock.
public final class RWLock: PThreadReadWriteLock, @unchecked Sendable {
    let rwLock: UnsafeMutablePointer<pthread_rwlock_t>
    
    /// Create a new read-write lock.
    public init() {
        rwLock = Self.pthreadInit()
    }

    /// Call `body` with a reading lock.
    ///
    /// - Parameter body: A function that reads a value while locked.
    /// - Returns: The value returned from the given function.
    public func withReadLock<T>(body: () throws -> T) rethrows -> T {
        pthreadWriteLock()
        defer {
            pthreadUnlock()
        }
        return try body()
    }

    /// Call `body` with a writing lock.
    ///
    /// - Parameter body: A function that writes a value while locked, then returns some value.
    /// - Returns: The value returned from the given function.
    public func withWriteLock<T>(body: () throws -> T) rethrows -> T {
        pthreadWriteLock()
        defer {
            pthreadUnlock()
        }
        return try body()
    }
    
    /// Determine if the lock is currently write locked.
    /// - Returns: Returns `true` if the lock is currently write locked.
    public func isWriteLocked() -> Bool {
        let status = pthread_rwlock_trywrlock(rwLock)

        // see status description https://developer.apple.com/library/archive/documentation/System/Conceptual/ManPages_iPhoneOS/man3/pthread_rwlock_trywrlock.3.html
        switch status {
        case 0:
            pthreadUnlock()
            return false
        case EBUSY: // The calling thread is not able to acquire the lock without blocking.
            return false // means we aren't locked
        case EDEADLK: // The calling thread already owns the read/write lock (for reading or writing).
            return true
        default:
            preconditionFailure("Unexpected status from pthread_rwlock_tryrdlock: \(status)")
        }
    }

    deinit {
        pthreadDeinit()
    }
}


extension PThreadReadWriteLock {
    static func pthreadInit() -> UnsafeMutablePointer<pthread_rwlock_t> {
        let lock: UnsafeMutablePointer<pthread_rwlock_t> = .allocate(capacity: 1)
        let status = pthread_rwlock_init(lock, nil)
        precondition(status == 0, "pthread_rwlock_init failed with status \(status)")
        return lock
    }

    func pthreadWriteLock() {
        let status = pthread_rwlock_wrlock(rwLock)
        assert(status == 0, "pthread_rwlock_wrlock failed with status \(status)")
    }

    func pthreadReadLock() {
        let status = pthread_rwlock_rdlock(rwLock)
        assert(status == 0, "pthread_rwlock_rdlock failed with status \(status)")
    }

    func pthreadUnlock() {
        let status = pthread_rwlock_unlock(rwLock)
        assert(status == 0, "pthread_rwlock_unlock failed with status \(status)")
    }

    func pthreadDeinit() {
        let status = pthread_rwlock_destroy(rwLock)
        assert(status == 0)
        rwLock.deallocate()
    }
}
