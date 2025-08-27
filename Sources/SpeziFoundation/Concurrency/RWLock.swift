//
// This source file is part of the Stanford Spezi open-source project
//
// SPDX-FileCopyrightText: 2024 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//


import Foundation


@_documentation(visibility: internal)
public protocol _PThreadReadWriteLock: AnyObject { // swiftlint:disable:this identifier_name
    // We need the unsafe mutable pointer, as otherwise we need to pass the property as inout parameter which isn't thread safe.
    var _rwLock: UnsafeMutablePointer<pthread_rwlock_t> { get } // swiftlint:disable:this identifier_name
    
    /// Call `body` with a reading lock.
    ///
    /// - Parameter body: A function that reads a value while locked.
    /// - Returns: The value returned from the given function.
    @inlinable
    func withReadLock<Result, E>(_ body: () throws(E) -> Result) throws(E) -> Result
    
    /// Call `body` with a writing lock.
    ///
    /// - Parameter body: A function that writes a value while locked, then returns some value.
    /// - Returns: The value returned from the given function.
    @inlinable
    func withWriteLock<Result, E>(_ body: () throws(E) -> Result) throws(E) -> Result
}


/// Read-Write Lock using `pthread_rwlock`.
///
/// Looking at [Benchmarking Swift Locking APIs](https://www.vadimbulavin.com/benchmarking-locking-apis) using `pthread_rwlock`
/// is favorable over using dispatch queues.
///
/// - Note: Refer to ``RecursiveRWLock`` if you need a recursive read-write lock.
public final class RWLock: _PThreadReadWriteLock, @unchecked Sendable {
    public let _rwLock: UnsafeMutablePointer<pthread_rwlock_t> // swiftlint:disable:this identifier_name
    
    /// Create a new read-write lock.
    public init() {
        _rwLock = Self.pthreadInit()
    }

    @inlinable
    public func withReadLock<Result, E>(_ body: () throws(E) -> Result) throws(E) -> Result {
        _pthreadWriteLock()
        defer {
            _pthreadUnlock()
        }
        return try body()
    }
    
    @inlinable
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


extension _PThreadReadWriteLock {
    static func pthreadInit() -> UnsafeMutablePointer<pthread_rwlock_t> {
        let lock: UnsafeMutablePointer<pthread_rwlock_t> = .allocate(capacity: 1)
        let status = pthread_rwlock_init(lock, nil)
        precondition(status == 0, "pthread_rwlock_init failed with status \(status)")
        return lock
    }

    @_documentation(visibility: internal)
    @inlinable
    public func _pthreadWriteLock() { // swiftlint:disable:this identifier_name
        let status = pthread_rwlock_wrlock(_rwLock)
        assert(status == 0, "pthread_rwlock_wrlock failed with status \(status)")
    }

    @_documentation(visibility: internal)
    @inlinable
    public func _pthreadReadLock() { // swiftlint:disable:this identifier_name
        let status = pthread_rwlock_rdlock(_rwLock)
        assert(status == 0, "pthread_rwlock_rdlock failed with status \(status)")
    }

    @_documentation(visibility: internal)
    @inlinable
    public func _pthreadUnlock() { // swiftlint:disable:this identifier_name
        let status = pthread_rwlock_unlock(_rwLock)
        assert(status == 0, "pthread_rwlock_unlock failed with status \(status)")
    }

    func pthreadDeinit() {
        let status = pthread_rwlock_destroy(_rwLock)
        assert(status == 0)
        _rwLock.deallocate()
    }
}
