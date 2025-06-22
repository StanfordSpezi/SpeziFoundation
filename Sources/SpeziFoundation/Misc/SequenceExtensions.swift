//
// This source file is part of the Stanford Spezi open-source project
//
// SPDX-FileCopyrightText: 2024 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import Algorithms


extension Sequence {
    /// Maps a `Sequence` into a `Set`.
    ///
    /// Compared to instead mapping the sequence into an `Array` (the default `map` function's return type) and then constructing a `Set` from that,
    /// this implementation can offer improved performance, since the intermediate `Array` is skipped.
    /// - Returns: a `Set` containing the results of applying `transform` to each element in the sequence.
    @inlinable
    public func mapIntoSet<NewElement: Hashable>(_ transform: (Element) throws -> NewElement) rethrows -> Set<NewElement> {
        var retval = Set<NewElement>()
        for element in self {
            retval.insert(try transform(element))
        }
        return retval
    }
    
    /// Maps a `Sequence` into a `Set`, skipping any `nil` elements.
    ///
    /// Compared to instead compact-mapping the sequence into an `Array` (the default `compactMap` function's return type) and then constructing a `Set` from that,
    /// this implementation can offer improved performance, since the intermediate `Array` is skipped.
    /// - Returns: a `Set` containing the results of applying `transform` to each element in the sequence, skipping all `nil` results.
    @inlinable
    public func compactMapIntoSet<NewElement: Hashable>(_ transform: (Element) throws -> NewElement?) rethrows -> Set<NewElement> {
        var retval = Set<NewElement>()
        for element in self {
            if let element = try transform(element) {
                retval.insert(element)
            }
        }
        return retval
    }
    
    /// Maps a `Sequence` into a `Set`, flattening the results of calling the `transform` closure with each element of the sequence.
    ///
    /// Compared to instead flat-mapping the sequence into an `Array` (the default `flatMap` function's return type) and then constructing a `Set` from that,
    /// this implementation can offer improved performance, since the intermediate `Array` is skipped.
    /// - Returns: a `Set` containing the flattened results of applying `transform` to each element in the sequence.
    @inlinable
    public func flatMapIntoSet<TransformResult: Sequence>(
        _ transform: (Element) throws -> TransformResult
    ) rethrows -> Set<TransformResult.Element> where TransformResult.Element: Hashable {
        var retval = Set<TransformResult.Element>()
        for element in self {
            retval.formUnion(try transform(element))
        }
        return retval
    }
    
    
    /// An asynchronous version of Swift's `Sequence.reduce(_:_:)` function.
    @inlinable
    public func reduce<Result>(
        _ initialResult: Result,
        _ nextPartialResult: (Result, Element) async throws -> Result
    ) async rethrows -> Result {
        var result = initialResult
        for element in self {
            result = try await nextPartialResult(result, element)
        }
        return result
    }
    
    /// An asynchronous version of Swift's `Sequence.reduce(into:_:)` function.
    @inlinable
    public func reduce<Result>(
        into initial: Result,
        _ nextPartialResult: (inout Result, Element) async throws -> Void
    ) async rethrows -> Result {
        var result = initial
        for element in self {
            try await nextPartialResult(&result, element)
        }
        return result
    }
}


extension Sequence {
    /// Determines whether the sequence is sorted w.r.t. the specified comparator.
    public func isSorted(by areInIncreasingOrder: (Element, Element) -> Bool) -> Bool {
        // ISSUE HERE: if we have a collection containing duplicate objects (eg: `[0, 0]`), and we want to check if it's sorted
        // properly (passing `{ $0 < $1 }`), that would incorrectly return false, because not all elements are ordered strictly ascending.
        // BUT: were we to sort the collection using the specified comparator, the sort result would be equivalent to the collection
        // itself. Meaning that we should consider it properly sorted.
        // We achieve this by reversing the comparator operands, and negating the result.
        self.adjacentPairs().allSatisfy { lhs, rhs in
            !areInIncreasingOrder(rhs, lhs)
        }
    }
}


extension RangeReplaceableCollection {
    /// Removes the elements at the specified indices from the collection.
    /// - parameter indices: The indices at which elements should be removed.
    ///
    /// Useful e.g. when working with SwiftUI's `onDelete(perform:)` modifier.
    @inlinable
    public mutating func remove(at indices: some Sequence<Index>) {
        for idx in indices.sorted().reversed() {
            self.remove(at: idx)
        }
    }
}


extension Collection {
    /// Safely accesses the elememt at the specified index, returning `nil` for out-of-bounds indices.
    @inlinable
    public subscript(safe index: Index) -> Element? {
        index >= startIndex && index < endIndex ? self[index] : nil
    }
}


extension Array {
    /// Unsafely accesses the element at the specified index, without performing any bounds checking.
    ///
    /// If `position` is not a valid index, the program will continue running as if 
    ///
    /// - Warning: This function trades safety for performance.
    ///     Use ``subscript(unsafe:)`` only in situations where your program can guarantee that `position` is valid for indexing into the array,
    ///     and only if the default bounds checking performed by the runtime has proven to be a significant performance problem.
    ///
    /// - Warning: This operation is unsafe, meaning that if `position` is not valid for indexing into the Array,
    ///     the program will nonetheless continue running, and will simply treat the memory at the resulting offset as if it were of type `Element`.
    public subscript(unsafe position: Int) -> Element {
        @_transparent
        get {
            withUnsafeBufferPointer { $0[position] }
        }
    }
}
