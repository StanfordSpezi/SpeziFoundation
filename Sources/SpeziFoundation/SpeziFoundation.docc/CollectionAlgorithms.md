# CollectionAlgorithms

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

SpeziFoundation provides a set of collection and sequence utilities that cover common algorithmic needs: efficient binary search over sorted collections, safe index access, order checking, and asynchronous reduction.

### Binary Search

Use ``Swift/Collection/binarySearchForIndex(of:using:)`` to locate an element in a sorted collection in O(log n) time. The comparator closure returns a `ComparisonResult` that guides the search direction. The result is a ``BinarySearchIndexResult``, which is either `.found` (with the element's index) or `.notFound` (with the index where the element would be inserted):

```swift
let words = ["apple", "banana", "cherry", "date", "elderberry"]

switch words.binarySearchForIndex(of: "cherry", using: { $0.compare($1) }) {
case .found(let index):
    print("Found at index \(index)")        // Found at index 2
case .notFound(let index):
    print("Not present; would belong at index \(index)")
}
```

### Safe Index Access

Use the ``Swift/Collection/subscript(safe:)`` subscript to access a collection element without risking an out-of-bounds crash. It returns `nil` for any index outside the valid range:

```swift
let items = ["a", "b", "c"]
let existing = items[safe: 1]   // Optional("b")
let missing  = items[safe: 10]  // nil
```

### Sequence Utilities

``Swift/Sequence/isSorted(by:)`` checks whether a sequence is ordered according to a given comparator, and ``Swift/Sequence/mapIntoSet(_:)`` maps a sequence directly into a `Set` without building an intermediate array:

```swift
let values = [1, 2, 3, 4]
let sorted = values.isSorted(by: <)   // true

let words = ["hello", "world", "hello"]
let unique = words.mapIntoSet { $0.uppercased() }   // Set(["HELLO", "WORLD"])
```

For async pipelines, ``Swift/Sequence/reduceAsync(_:_:)`` mirrors `Sequence.reduce(_:_:)` but accepts an `async throws` accumulator closure:

```swift
let totalSize = try await urls.reduceAsync(0) { partial, url in
    let (data, _) = try await URLSession.shared.data(from: url)
    return partial + data.count
}
```

## Topics

### Binary Search
- ``Swift/Collection/binarySearchForIndex(of:using:)``
- ``BinarySearchIndexResult``

### Sequence and Collection operations
- ``Swift/Sequence/isSorted(by:)``
- ``Swift/Sequence/sorted(using:)``
- ``Swift/Sequence/mapIntoSet(_:)``
- ``Swift/MutableCollection/sort(using:)``
- ``Swift/RangeReplaceableCollection/remove(at:)``
- ``Swift/Collection/subscript(safe:)``
- ``Swift/Array/subscript(unsafe:)``
