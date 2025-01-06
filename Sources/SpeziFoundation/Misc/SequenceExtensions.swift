//
//  File.swift
//  SpeziFoundation
//
//  Created by Lukas Kollmer on 2024-12-27.
//

import Foundation
import Algorithms


extension Sequence {
    /// Maps a `Sequence` into a `Set`.
    /// Compared to instead mapping the sequence into an Array (the default `map` function's return type) and then constructing a `Set` from that,
    /// this implementation can offer improved performance, since the intermediate Array is skipped.
    /// - Returns: a `Set` containing the results of applying `transform` to each element in the sequence.
    /// - Throws: If `transform` throws.
    public func mapIntoSet<NewElement: Hashable>(_ transform: (Element) throws -> NewElement) rethrows -> Set<NewElement> {
        var retval = Set<NewElement>()
        for element in self {
            retval.insert(try transform(element))
        }
        return retval
    }
}



extension Sequence {
    public func lk_isSorted(by areInIncreasingOrder: (Element, Element) -> Bool) -> Bool {
        // ISSUE HERE: if we have a collection containing duplicate objects (eg: `[0, 0]`), and we want to check if it's sorted
        // properly (passing `{ $0 < $1 }`), that would incorrectly return false, because not all elements are ordered strictly ascending.
        // BUT: were we to sort the collection using the specified comparator, the sort result would be equivalent to the collection
        // itself. Meaning that we should consider it properly sorted.
        // We achieve this by reversing the comparator operands, and negating the result.
        return self.adjacentPairs().allSatisfy { a, b in
            !areInIncreasingOrder(b, a)
        }
    }
    
    
    /// Returns whether the sequence is sorted ascending, w.r.t. the specified key path.
    /// - Note: if two or more adjacent elements in the sequence are equal to each other, the sequence will still be considered sorted.
    public func lk_isSorted(by keyPath: KeyPath<Element, some Comparable>) -> Bool {
        return self.adjacentPairs().allSatisfy {
            $0[keyPath: keyPath] <= $1[keyPath: keyPath]
        }
    }
    
    public func lk_isSortedStrictlyAscending(by keyPath: KeyPath<Element, some Comparable>) -> Bool {
        return self.adjacentPairs().allSatisfy {
            $0[keyPath: keyPath] < $1[keyPath: keyPath]
        }
    }
}




extension RangeReplaceableCollection {
    public mutating func remove(at indices: some Sequence<Index>) {
        for idx in indices.sorted().reversed() {
            self.remove(at: idx)
        }
    }
    
    
    public mutating func removeAll(where predicate: (Element) throws -> Bool) rethrows {
        self = try self.filter { try !predicate($0) }
    }
}
