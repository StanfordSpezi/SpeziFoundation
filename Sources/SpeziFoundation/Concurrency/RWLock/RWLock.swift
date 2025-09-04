//
// This source file is part of the Stanford Spezi open-source project
//
// SPDX-FileCopyrightText: 2024 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

#if canImport(pthread)
public import pthread
#endif
#if canImport(Glibc)
public import Glibc
#endif

/// Read-Write Lock using `pthread_rwlock`.
///
/// Looking at [Benchmarking Swift Locking APIs](https://www.vadimbulavin.com/benchmarking-locking-apis) using `pthread_rwlock`
/// is favorable over using dispatch queues.
///
/// - Note: Refer to ``RecursiveRWLock`` if you need a recursive read-write lock.
public final class RWLock: _PThreadReadWriteLockProtocol, @unchecked Sendable {
    public let _rwLock: UnsafeMutablePointer<pthread_rwlock_t> // swiftlint:disable:this identifier_name
    
    /// Create a new read-write lock.
    public init() {
        _rwLock = Self.pthreadInit()
    }

    @inlinable
    @inline(__always)
    public func withReadLock<Result, E>(_ body: () throws(E) -> Result) throws(E) -> Result {
        _pthreadWriteLock()
        defer {
            _pthreadUnlock()
        }
        return try body()
    }
    
    @inlinable
    @inline(__always)
    public func withWriteLock<Result, E>(_ body: () throws(E) -> Result) throws(E) -> Result {
        _pthreadWriteLock()
        defer {
            _pthreadUnlock()
        }
        return try body()
    }
    
    /// Determine if the lock is currently write locked.
    /// - Returns: Returns `true` if the lock is currently write locked.
    @inlinable
    public func isWriteLocked() -> Bool {
        let status = pthread_rwlock_trywrlock(_rwLock)
        // see status description https://developer.apple.com/library/archive/documentation/System/Conceptual/ManPages_iPhoneOS/man3/pthread_rwlock_trywrlock.3.html
        switch status {
        case 0:
            _pthreadUnlock()
            return false
        case EBUSY: // The calling thread is not able to acquire the lock without blocking.
            return false // means we aren't locked
        case EDEADLK: // The calling thread already owns the read/write lock (for reading or writing).
            return true
        default:
            preconditionFailure("Unexpected status from pthread_rwlock_trywrlock: \(status)")
        }
    }

    deinit {
        pthreadDeinit()
    }
}
