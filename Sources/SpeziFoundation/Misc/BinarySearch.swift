//
// This source file is part of the Stanford Spezi open-source project
//
// SPDX-FileCopyrightText: 2025 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import enum Foundation.ComparisonResult


/// The result of a binary search looking for some element in a collection.
public enum BinarySearchIndexResult<Index> {
    /// The searched-for element was found in the collection, at the specified index.
    case found(Index)
    /// The searched-for element was not found in the collection, but if it were a member of the collection, it would belong at the specified index.
    case notFound(Index)
}


extension BinarySearchIndexResult: Equatable where Index: Equatable {}
extension BinarySearchIndexResult: Hashable where Index: Hashable {}


extension Collection {
    /// Performs a binary search over the collection, looking for
    /// - parameter compare: closure that gets called with an element of the collection to determine, whether the binary search algorithm should go left/right, or has already found its target.
    ///         The closure should return `.orderedSame` if the element passed to it matches the search destination, `.orderedAscending` if the search should continue to the left,
    ///         and `.orderedDescending` if it should continue to the right.
    ///         E.g., when looking for a position for an element `x`, the closure should perform a `compare(x, $0)`.
    public func binarySearchForIndex(
        of element: Element,
        using compare: (Element, Element) -> ComparisonResult
    ) -> BinarySearchIndexResult<Index> {
        binarySearchForIndex(of: element, in: startIndex..<endIndex, using: compare)
    }
    
    /// Performs a binary search over the collection, looking for the index at which the element either is, or should be if it were a member of the collection.
    /// - parameter element: The element whose position should be determined.
    /// - parameter range: The range in which to look for the element.
    /// - parameter compare: Closure used to compare two  `Element`s against each other. The result of this is used to determine, if the elements are not equal,
    ///         whether the binary search algorithm should continue to the left or to the right.
    ///         The closure should return `.orderedSame` if the element passed to it matches the search destination, `.orderedAscending` if the search should continue to the left,
    ///         and `.orderedDescending` if it should continue to the right.
    public func binarySearchForIndex(
        of element: Element,
        in range: Range<Index>,
        using compare: (Element, Element) -> ComparisonResult
    ) -> BinarySearchIndexResult<Index> {
        guard let middle: Self.Index = middleIndex(of: range) else {
            return .notFound(range.upperBound)
        }
        switch compare(element, self[middle]) {
        case .orderedAscending: // lhs < rhs
            return binarySearchForIndex(of: element, in: range.lowerBound..<middle, using: compare)
        case .orderedDescending: // lhs > rhs
            return binarySearchForIndex(of: element, in: index(after: middle)..<range.upperBound, using: compare)
        case .orderedSame: // lhs == rhs
            return .found(middle)
        }
    }
    
    /// Computes, for a non-empty range over the collection, the middle of the range.
    /// If the range is empty, this function will return `nil`.
    public func middleIndex(of range: Range<Index>) -> Index? {
        guard !range.isEmpty else {
            return nil
        }
        let distance = self.distance(from: range.lowerBound, to: range.upperBound)
        let resultIdx = self.index(range.lowerBound, offsetBy: distance / 2)
        return resultIdx
    }
}
