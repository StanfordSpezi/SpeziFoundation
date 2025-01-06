//
//  File.swift
//  SpeziFoundation
//
//  Created by Lukas Kollmer on 2024-12-25.
//

import Foundation
import SpeziFoundationObjC


/// A `Swift.Error` wrapping around an `NSException`.
public struct CaughtNSException: Error, LocalizedError, @unchecked Sendable {
    public let exception: NSException
    
    public var errorDescription: String? {
        return "\(Self.self): \(exception.description)"
    }
}


/// Invokes the specified closure and handles any potentially raised Objective-C `NSException` objects,
/// rethrowing them wrapped as ``CaughtNSException`` errors. Swift errors thrown in the closure will also be caught and rethrown.
/// - parameter block: the closure that should be invoked
/// - returns: the return value of `block`, provided that no errors or exceptions were thrown
/// - throws: if the block throws an `NSException` or a Swift `Error`, it will be rethrown.
public func catchingNSException<T>(_ block: () throws -> T) throws -> T {
    var retval: T?
    var caughtSwiftError: (any Swift.Error)?
    let caughtNSException = InvokeBlockCatchingNSExceptionIfThrown {
        do {
            retval = try block()
        } catch {
            caughtSwiftError = error
        }
    }
    
    switch (retval, caughtNSException, caughtSwiftError) {
    case (.some(let retval), .none, .none):
        return retval
    case (.none, .some(let exc), .none):
        throw CaughtNSException(exception: exc)
    case (.none, .none, .some(let error)):
        throw error
    default:
        // unreachable
        fatalError("""
            Invalid state. Exactly one of retval, caughtNSException, and caughtSwiftError should be non-nil.
            retval: \(String(describing: retval))
            caughtNSException: \(String(describing: caughtNSException))
            caughtSwiftError: \(String(describing: caughtSwiftError))
            """
        )
    }
}
