//
// This source file is part of the Stanford Spezi open-source project
//
// SPDX-FileCopyrightText: 2024 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

public import Foundation


extension Sequence {
    /// Returns the elements of the sequence, sorted using the given array of
    /// `SortComparator`s to compare elements.
    ///
    /// - parameter comparators: a sequence of comparators used to compare elements.
    ///     The first comparator specifies the primary comparator to be used in
    ///     sorting the sequence's elements. Any subsequent comparators are used
    ///     to further refine the order of elements with equal values.
    /// - returns: an array of the elements sorted using `comparators`.
    @_disfavoredOverload
    @inlinable
    public func sorted(using comparators: some Sequence<any SortComparator<Element>>) -> [Element] {
        var copy = Array(self)
        copy.sort(using: comparators)
        return copy
    }
}


extension MutableCollection where Self: RandomAccessCollection {
    /// Sorts the collection using the given array of `SortComparator`s to
    /// compare elements.
    ///
    /// - parameter comparators: a sequence of comparators used to compare elements.
    ///     The first comparator specifies the primary comparator to be used in
    ///     sorting the sequence's elements. Any subsequent comparators are used
    ///     to further refine the order of elements with equal values.
    @_disfavoredOverload
    @inlinable
    public mutating func sort(using comparators: some Sequence<any SortComparator<Element>>) {
        guard let primaryComparator = comparators.first(where: { _ in true }) else {
            return
        }
        self.sort { lhs, rhs in
            switch primaryComparator.compare(lhs, rhs) {
            case ComparisonResult.orderedAscending:
                return true
            case ComparisonResult.orderedDescending:
                return false
            case ComparisonResult.orderedSame:
                for comparator in comparators.dropFirst() {
                    switch comparator.compare(lhs, rhs) {
                    case .orderedAscending:
                        return true
                    case .orderedDescending:
                        return false
                    case .orderedSame:
                        continue
                    }
                }
                return false
            }
        }
    }
}
