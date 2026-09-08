# Collection Algorithms

<!--
#
# This source file is part of the Stanford Spezi open-source project
#
# SPDX-FileCopyrightText: 2025 Stanford University and the project authors (see CONTRIBUTORS.md)
#
# SPDX-License-Identifier: MIT
#
-->

Binary search over Collections, and other Sequence extensions

## Overview

SpeziFoundation extends the standard library's `Sequence` and `Collection` protocols with a small set of algorithms that come up repeatedly across Spezi modules:
binary search over sorted collections, `Set`-producing variants of `map`, sorting with heterogeneous comparators, and a few safety and convenience helpers.

### Binary Search

``Swift/Collection/binarySearchForIndex(of:using:)`` locates an element in an already-sorted collection in O(log n) time.
Unlike `firstIndex(of:)`, it needs to know how the elements are ordered, which you express through a comparator closure that returns a `ComparisonResult`.

The closure receives two arguments: the element you are looking for, and an element from the collection.
It returns how the searched-for element compares to the collection element:
- `.orderedAscending`: the searched-for element belongs *before* the collection element; the search continues to the left.
- `.orderedDescending`: it belongs *after* the collection element; the search continues to the right.
- `.orderedSame`: the two are equivalent; the search ends.

A `Bool`-returning comparator (such as `<` or `==`) is not sufficient here, since a single comparison needs to tell the algorithm which half of the collection to discard.
For `Comparable` elements, a small helper keeps call sites readable:

```swift
extension Comparable {
    static func compare(_ lhs: Self, _ rhs: Self) -> ComparisonResult {
        lhs < rhs ? .orderedAscending : lhs > rhs ? .orderedDescending : .orderedSame
    }
}

let sortedIds = [3, 8, 15, 42, 99]
sortedIds.binarySearchForIndex(of: 15, using: Int.compare) // .found(2)
sortedIds.binarySearchForIndex(of: 20, using: Int.compare) // .notFound(3)
```

The result is a ``BinarySearchIndexResult``. It doesn't only tell you whether the element was found:
if it wasn't, `.notFound` carries the index at which the element would have to be inserted to keep the collection sorted.
This is what makes binary search useful for *maintaining* sorted collections, and it is exactly how ``OrderedArray`` keeps its elements in order:

```swift
var sortedIds = [3, 8, 15, 42, 99]

func insertKeepingOrder(_ id: Int) {
    switch sortedIds.binarySearchForIndex(of: id, using: Int.compare) {
    case .found(let index), .notFound(let index):
        sortedIds.insert(id, at: index)
    }
}
```

> Note: If the collection contains several elements that compare as `.orderedSame` to the searched-for element,
> `.found` reports the index of *one* of them, which is not necessarily the first. Use the technique described below if you need the boundaries of such a run.

#### Range Queries

``Swift/Collection/binarySearchFirstIndex(where:)`` is the lower-level building block behind `binarySearchForIndex(of:using:)`.
Its closure receives only the collection element and returns where the position you are looking for lies relative to that element.
Since the closure isn't tied to a specific element, it can search for a *position* instead, such as the first element that satisfies a predicate.
This turns a sorted collection into something that can be sliced by value ranges in O(log n), for example to select all samples that fall into a time window:

```swift
extension Collection {
    /// Returns the index of the first element for which `predicate` is `true`, or `endIndex` if there is none.
    ///
    /// The collection must be partitioned w.r.t. `predicate`, i.e., all elements for which it returns `false` must precede
    /// all elements for which it returns `true`. This is the case, e.g., for a collection sorted by date and a predicate of the form `$0.date >= cutoff`.
    func partitionIndex(where predicate: (Element) -> Bool) -> Index {
        // The closure never returns `.orderedSame`, so the search always ends in `.notFound`, positioned at the first element satisfying the predicate.
        switch binarySearchFirstIndex(where: { predicate($0) ? .orderedAscending : .orderedDescending }) {
        case .found(let index), .notFound(let index):
            index
        }
    }
}

let samples: [Sample] = ... // sorted by `startDate`
let window: Range<Date> = ...

let start = samples.partitionIndex { $0.startDate >= window.lowerBound }
let end = samples.partitionIndex { $0.startDate >= window.upperBound }
let samplesInWindow = samples[start..<end] // two O(log n) searches, regardless of how many samples there are
```

> Tip: The [swift-algorithms](https://github.com/apple/swift-algorithms) package offers this exact operation as `partitioningIndex(where:)`.

### Sorting with Multiple Comparators

Foundation's `sorted(using:)` accepts a sequence of `SortComparator`s, but requires all of them to be of the same concrete type.
SpeziFoundation's ``Swift/Sequence/sorted(using:)`` and ``Swift/MutableCollection/sort(using:)`` overloads lift that restriction by accepting existential `any SortComparator<Element>` values,
so that comparators of different types can be combined. The first comparator defines the primary order; subsequent comparators break ties:

```swift
struct Participant {
    let name: String
    let hasOpenTasks: Bool
}

/// Orders participants with open tasks before those without.
struct OpenTasksFirst: SortComparator {
    var order: SortOrder = .forward

    func compare(_ lhs: Participant, _ rhs: Participant) -> ComparisonResult {
        switch (lhs.hasOpenTasks, rhs.hasOpenTasks) {
        case (true, false): order == .forward ? .orderedAscending : .orderedDescending
        case (false, true): order == .forward ? .orderedDescending : .orderedAscending
        default: .orderedSame
        }
    }
}

let sorted = participants.sorted(using: [
    OpenTasksFirst(),
    KeyPathComparator(\Participant.name)
] as [any SortComparator<Participant>])
```

### Checking Sort Order

``Swift/Sequence/isSorted(by:)`` determines whether a sequence is ordered w.r.t. a comparator, e.g. to validate input before handing it to one of the binary search functions above.
The check passes if sorting the sequence with the comparator would leave it unchanged, i.e., if no two *adjacent* elements are out of order.
Adjacent elements that compare equal are therefore allowed: `[0, 0].isSorted(by: <)` is `true`, even though `0 < 0` is not.

### Mapping into Sets

``Swift/Sequence/mapIntoSet(_:)``, ``Swift/Sequence/compactMapIntoSet(_:)``, and ``Swift/Sequence/flatMapIntoSet(_:)`` produce a `Set` directly,
skipping the intermediate `Array` that `Set(sequence.map { ... })` would allocate.
Use them wherever the result is only needed for membership tests or deduplication, e.g. `let sampleTypes = samples.mapIntoSet(\.sampleType)`.

### Indexing and Removal

- ``Swift/Collection/subscript(safe:)`` returns `nil` instead of trapping for out-of-bounds indices, e.g. `items[safe: 10]`, which is useful when an index originates from external input.
- ``Swift/Array/subscript(unsafe:)`` makes the opposite trade-off: it skips bounds checking entirely. Reserve it for hot paths where the index is provably valid.
- ``Swift/RangeReplaceableCollection/remove(at:)`` removes the elements at multiple indices at once (e.g., the `IndexSet` passed to SwiftUI's `onDelete(perform:)` modifier),
  taking care of the index shifting that would otherwise make this error-prone.
- ``Swift/BidirectionalCollection/ends(with:)`` checks whether a collection ends with another one, similar to `starts(with:)`;
  SpeziLocalization uses it to match file names against the trailing path components of a `URL`.

## Topics

### Binary Search
- ``Swift/Collection/binarySearchForIndex(of:using:)``
- ``Swift/Collection/binarySearchFirstIndex(where:)``
- ``BinarySearchIndexResult``

### Sorting
- ``Swift/Sequence/isSorted(by:)``
- ``Swift/Sequence/sorted(using:)``
- ``Swift/MutableCollection/sort(using:)``

### Mapping into Sets
- ``Swift/Sequence/mapIntoSet(_:)``
- ``Swift/Sequence/compactMapIntoSet(_:)``
- ``Swift/Sequence/flatMapIntoSet(_:)``

### Indexing and Removal
- ``Swift/Collection/subscript(safe:)``
- ``Swift/Array/subscript(unsafe:)``
- ``Swift/RangeReplaceableCollection/remove(at:)``
- ``Swift/BidirectionalCollection/ends(with:)``
- ``Swift/BidirectionalCollection/ends(with:by:)``
