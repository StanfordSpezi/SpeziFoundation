//
// This source file is part of the Stanford Spezi open-source project.
// It is based on the code from the Apodini (https://github.com/Apodini/Apodini) project.
//
// SPDX-FileCopyrightText: 2023 Stanford University and the project authors (see CONTRIBUTORS.md) and the Apodini project authors
//
// SPDX-License-Identifier: MIT
//


/// A type erased `Optional`.
///
/// This is useful to unwrapping, e.g.,  generics or associated types by declaring an extension under the condition of
/// ``AnyOptional`` conformance. This allows in the implementation of the extension to access the underlying
/// ``Wrapped`` type of an `Optional`, essentially unwrapping the optional type.
///
/// ``AnyOptional`` conforms to the [`ExpressibleByNilLiteral`](https://developer.apple.com/documentation/swift/expressiblebynilliteral) protocol.
/// Apple states that only the `Optional` type conforms to `ExpressibleByNilLiteral`. `ExpressibleByNilLiteral` conformance for types that use `nil for other purposes is discouraged.
public protocol AnyOptional: ExpressibleByNilLiteral {
    /// The underlying type of the Optional
    associatedtype Wrapped


    /// This property provides access to the underlying Optional
    var unwrappedOptional: Optional<Wrapped> { get }
    // swiftlint:disable:previous syntactic_sugar
    // Disabling syntactic_sugar, improves readability and showcases what really happens here.
}


extension Optional: AnyOptional {
    // Disabling syntactic_sugar, improves readability and showcases what really happens here.
    // swiftlint:disable:next syntactic_sugar
    public var unwrappedOptional: Optional<Wrapped> {
        self
    }
}
