//
//  File.swift
//  SpeziFoundation
//
//  Created by Lukas Kollmer on 2024-12-27.
//

import Foundation



/// An array that keeps its elements sorted in a way that satisfies a user-provided total order.
public struct SortedArray<Element> { // TODO SortedArray? OrderedArray?
    public typealias Comparator = (Element, Element) -> Bool
    public typealias Storage = Array<Element>
    
    /// The total order used to compare elements.
    /// When comparing two elements, it should return `true` if their ordering satisfies the relation, otherwise `false`.
    public let areInIncreasingOrder: Comparator
    
    private var storage: Storage {
        didSet { if shouldAssertInvariantAfterMutations { assertInvariant() } }
    }
    
    /// Whether the array should assert its invariant after every mutation
    var shouldAssertInvariantAfterMutations = true {
        didSet {
            if shouldAssertInvariantAfterMutations && !oldValue {
                assertInvariant()
            }
        }
    }
    
    
    public init() where Element: Comparable {
        self.storage = []
        self.areInIncreasingOrder = { $0 < $1 }
    }
    
    public init(areInIncreasingOrder: @escaping Comparator) {
        self.storage = []
        self.areInIncreasingOrder = areInIncreasingOrder
    }
    
    public init(keyPath: KeyPath<Element, some Comparable>) {
        self.storage = []
        self.areInIncreasingOrder = { $0[keyPath: keyPath] < $1[keyPath: keyPath] }
    }
    
    public init(_ sequence: some Sequence<Element>, areInIncreasingOrder: @escaping Comparator) {
        self.storage = sequence.sorted(by: areInIncreasingOrder)
        self.areInIncreasingOrder = areInIncreasingOrder
    }
    
    
    /// Performs mutations on the array as a single transaction, with invariant checks disabled for the duration of the mutations
    mutating func withInvariantCheckingTemporarilyDisabled<Result>(_ block: (inout SortedArray<Element>) -> Result) -> Result {
        let prevValue = shouldAssertInvariantAfterMutations
        shouldAssertInvariantAfterMutations = false
        let retval = block(&self)
        shouldAssertInvariantAfterMutations = prevValue
        return retval
    }
    
    
//    func lk_intoArray() -> [Element] {
//        return self.storage
//    }
}


//extension Array {
//    init(_ other: SortedArray<Element>) {
//        self = other.lk_intoArray()
//    }
//}


extension SortedArray: CustomStringConvertible, CustomDebugStringConvertible {
    public var description: String {
        storage.description
    }
    
    public var debugDescription: String {
        storage.debugDescription
    }
}


// MARK: RandomAccessCollection

extension SortedArray: RandomAccessCollection {
    public typealias Index = Storage.Index
    
    public var startIndex: Index {
        storage.startIndex
    }
    public var endIndex: Index {
        storage.endIndex
    }
    
    public func index(before idx: Index) -> Index {
        storage.index(before: idx)
    }
    
    public func index(after idx: Index) -> Index {
        storage.index(after: idx)
    }
    
    public subscript(position: Index) -> Element {
        storage[position]
    }
    
    public func _customIndexOfEquatableElement(_ element: Element) -> Index?? {
        return Optional<Index?>.some(firstIndex(of: element))
    }
}



// MARK: Equatable, Hashable

extension SortedArray: Equatable where Element: Equatable {
    /// - Note: This ignores the comparator!!!
    public static func == (lhs: SortedArray<Element>, rhs: SortedArray<Element>) -> Bool {
        return lhs.storage == rhs.storage
    }
}


extension SortedArray: Hashable where Element: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(storage)
    }
}






// MARK: Invariant Checking

extension SortedArray {
    /// Assert that the array is sorted according to its invariant.
    public func assertInvariant() {
        precondition(self.lk_isSorted(by: areInIncreasingOrder))
    }
}





// MARK: Insertion, Removal, Mutation, Other

extension SortedArray {
    @discardableResult
    public mutating func insert(_ element: Element) -> Index {
        let insertionIdx: Index
        switch search(for: element) {
        case .found(let idx):
            insertionIdx = idx
        case .notFound(let idx):
            insertionIdx = idx
        }
        storage.insert(element, at: insertionIdx)
        return insertionIdx
    }
    
    
    public mutating func unsafelyInsert(_ element: Element, at idx: Index) {
        storage.insert(element, at: idx)
    }
    
    
    public mutating func insert(contentsOf sequence: some Sequence<Element>) {
        withInvariantCheckingTemporarilyDisabled { `self` in
            for element in sequence {
                self.insert(element)
            }
        }
    }
    
    
    public mutating func insert2(contentsOf sequence: some Sequence<Element>) -> Set<Index> { // TODO better name!
        return withInvariantCheckingTemporarilyDisabled { `self` in
            var insertionIndices = Set<Index>()
            for element in sequence {
                let idx = self.insert(element)
                // since the insertions won't necessarily happen in order, we need to adjust the indices as we insert.
                insertionIndices = insertionIndices.mapIntoSet {
                    $0 < idx ? $0 : self.index(after: $0)
                }
                insertionIndices.insert(idx)
            }
            return insertionIndices
        }
    }
    
    
    @discardableResult
    public mutating func remove(at index: Index) -> Element {
        return storage.remove(at: index)
    }
    
    
    /// Removes all occurrences of the objects in `elements` from the array.
    /// - returns: the indices of the removed objects
    @discardableResult
    public mutating func remove(contentsOf elements: some Sequence<Element>) -> [Index] where Element: Equatable {
        return withInvariantCheckingTemporarilyDisabled { `self` in
            let indices = elements.compactMap { element in
                // In the case of removals, we also perform a cringe O(n) search for the to-be-removed element,
                // if the default binary search didn't yield a result.
                // This is requied because we might be removing an element whose "correct" position in the
                // array has changed, in which case we would not necessarily be able to find it via the normal search.
                self.firstIndex(of: element) ?? self.indices.first { self[$0] == element }
            }
            self.storage.remove(at: indices)
            return indices
        }
    }
    
    
    /// Removes from the array all elements which match the predicate
    @discardableResult
    public mutating func removeAll(where predicate: (Element) -> Bool) -> [Index] {
        return withInvariantCheckingTemporarilyDisabled { `self` in
            let indices = self.enumerated().compactMap { predicate($0.element) ? $0.offset : nil }
            self.storage.remove(at: indices)
            return indices
        }
    }
    
    
    public mutating func removeAll(keepingCapacity: Bool = false) {
        storage.removeAll(keepingCapacity: keepingCapacity)
    }
    
    
    public mutating func unsafelyMutate(at index: Index, with transform: (inout Element) throws -> Void) rethrows {
        try transform(&storage[index])
    }
    
    
    
    public func firstIndex(of element: Element) -> Index? {
        switch search(for: element) {
        case .found(let idx):
            return idx
        case .notFound:
            return nil
        }
    }
    
    public mutating func removeFirstOccurrence(of element: Element) -> Index? {
        if let idx = firstIndex(of: element) {
            remove(at: idx)
            return idx
        } else {
            return nil
        }
    }
    
    
    public func contains(_ element: Element) -> Bool {
        return firstIndex(of: element) != nil
    }
}



// MARK: Position Finding etc

extension SortedArray {
    fileprivate func compare(_ lhs: Element, _ rhs: Element) -> ComparisonResult {
        if areInIncreasingOrder(lhs, rhs) {
            return .orderedAscending
        } else if areInIncreasingOrder(rhs, lhs) {
            return .orderedDescending
        } else {
            return .orderedSame
        }
    }
    
    public typealias SearchResult = BinarySearchIndexResult<Index>
    
    
    public func search(for element: Element) -> SearchResult {
        return lk_binarySearchFirstIndex {
            switch compare(element, $0) {
            case .orderedSame:
                return .match
            case .orderedAscending:
                return .continueLeft
            case .orderedDescending:
                return .continueRight
            }
        }
    }
}




// MARK: Binary Search


public enum BinarySearchIndexResult<Index> {
    case found(Index)
    case notFound(Index)
    
    public var index: Index {
        switch self {
        case .found(let index), .notFound(let index):
            return index
        }
    }
}

extension BinarySearchIndexResult: Equatable where Index: Equatable {}
extension BinarySearchIndexResult: Hashable where Index: Hashable {}


public enum BinarySearchComparisonResult {
    case match
    case continueLeft
    case continueRight
}


extension Collection {
    /// - parameter compare: closure that gets called with an element of the collection to determine, whether the binary search algorithm should go left/right, or has already found its target.
    ///         The closure should return `.orderedSame` if the element passed to it matches the search destination, `.orderedAscending` if the search should continue to the left,
    ///         and `.orderedDescending` if it should continue to the right.
    ///         E.g., when looking for a position for an element `x`, the closure should perform a `compare(x, $0)`.
    public func lk_binarySearchFirstIndex(using compare: (Element) -> BinarySearchComparisonResult) -> BinarySearchIndexResult<Index> {
        return lk_binarySearchFirstIndex(in: startIndex..<endIndex, using: compare)
    }
    
    /// - parameter compare: closure that gets called with an element of the collection to determine, whether the binary search algorithm should go left/right, or has already found its target.
    ///         The closure should return `.orderedSame` if the element passed to it matches the search destination, `.orderedAscending` if the search should continue to the left,
    ///         and `.orderedDescending` if it should continue to the right.
    ///         E.g., when looking for a position for an element `x`, the closure should perform a `compare(x, $0)`.
    public func lk_binarySearchFirstIndex(in range: Range<Index>, using compare: (Element) -> BinarySearchComparisonResult) -> BinarySearchIndexResult<Index> {
        guard let middle: Self.Index = lk_middleIndex(of: range) else {
            return .notFound(range.upperBound)
        }
        switch compare(self[middle]) {
        case .continueLeft: // lhs < rhs
            return lk_binarySearchFirstIndex(in: range.lowerBound..<middle, using: compare)
        case .continueRight: // lhs > rhs
            return lk_binarySearchFirstIndex(in: index(after: middle)..<range.upperBound, using: compare)
        case .match: // lhs == rhs
            return .found(middle)
        }
    }
    
    
    public func lk_middleIndex(of range: Range<Index>) -> Index? {
        guard !range.isEmpty else {
            return nil
        }
        let distance = self.distance(from: range.lowerBound, to: range.upperBound)
        let resultIdx = self.index(range.lowerBound, offsetBy: distance / 2)
        return resultIdx
    }
}

