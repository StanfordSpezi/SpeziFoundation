//
// This source file is part of the Stanford Spezi open-source project
//
// SPDX-FileCopyrightText: 2025 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import pthread


@_documentation(visibility: internal)
public protocol _PThreadReadWriteLockProtocol: AnyObject { // swiftlint:disable:this identifier_name
    // We need the unsafe mutable pointer, as otherwise we need to pass the property as inout parameter which isn't thread safe.
    var _rwLock: UnsafeMutablePointer<pthread_rwlock_t> { get } // swiftlint:disable:this identifier_name
    
    /// Call `body` with a reading lock.
    ///
    /// - Parameter body: A function that reads a value while locked.
    /// - Returns: The value returned from the given function.
    @inlinable @inline(__always)
    func withReadLock<Result, E>(_ body: () throws(E) -> Result) throws(E) -> Result
    
    /// Call `body` with a writing lock.
    ///
    /// - Parameter body: A function that writes a value while locked, then returns some value.
    /// - Returns: The value returned from the given function.
    @inlinable @inline(__always)
    func withWriteLock<Result, E>(_ body: () throws(E) -> Result) throws(E) -> Result
}


extension _PThreadReadWriteLockProtocol {
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


// MARK: Deprecations

extension _PThreadReadWriteLockProtocol {
    @_documentation(visibility: internal)
    @available(*, deprecated, renamed: "withReadLock(_:)")
    public func withReadLock<Result>(body: () throws -> Result) rethrows -> Result {
        try withReadLock(body)
    }
    
    @_documentation(visibility: internal)
    @available(*, deprecated, renamed: "withWriteLock(_:)")
    func withWriteLock<Result>(body: () throws -> Result) rethrows -> Result {
        try withWriteLock(body)
    }
}
