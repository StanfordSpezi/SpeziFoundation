<!--
This source file is part of the Stanford Spezi open-source project

SPDX-FileCopyrightText: 2026 Stanford University and the project authors (see CONTRIBUTORS.md)

SPDX-License-Identifier: MIT
-->

# OrderedArray

A sorted array that automatically places every inserted element in the correct position according to a user-defined comparator.

## Overview

``OrderedArray`` is an `Array`-like data structure that maintains a strict total order over its elements at all times. Rather than appending elements and sorting after the fact, every insertion uses a binary search to find the right position, keeping the collection sorted without any extra bookkeeping from the caller.

The type conforms to `RandomAccessCollection`, so all standard collection algorithms — `map`, `filter`, `forEach`, slicing, and index-based access — work out of the box. `contains(_:)` and `firstIndex(of:)` are automatically accelerated to O(log n) binary-search lookups.

> Important: `OrderedArray` does not observe mutations to individual elements. If an element changes in a way that affects its ordering, the invariant will no longer hold. Either treat elements as immutable with respect to the comparator, or remove and re-insert them after mutation.

> Note: `OrderedArray` intentionally does not conform to `Equatable` or `Hashable` because its comparator is a closure and cannot be compared or hashed. To compare the contents of two `OrderedArray` instances, use `Sequence.elementsEqual(_:)`.

### Creating an OrderedArray

Supply any closure that defines a strict weak ordering (`<`-style semantics):

```swift
// Ordered by a custom comparator
var scores = OrderedArray<Int> { $0 < $1 }

// For Comparable elements you can forward the < operator directly
var words = OrderedArray<String>(areInIncreasingOrder: <)
```

### Inserting Elements

Call ``OrderedArray/insert(_:)`` to add a single element. The return value is the index at which it was placed, but you can discard it if you don't need it:

```swift
scores.insert(42)
scores.insert(7)
scores.insert(23)

print(scores)  // OrderedArray([7, 23, 42])
```

To bulk-insert from any `Sequence`, use ``OrderedArray/insert(contentsOf:)``:

```swift
scores.insert(contentsOf: [100, 1, 55])
print(scores)  // OrderedArray([1, 7, 23, 42, 55, 100])
```

### Binary Search and Membership Testing

`contains(_:)` and `firstIndex(of:)` use binary search internally and run in O(log n). For lower-level access to the binary-search result — including the insertion point when an element is absent — use ``OrderedArray/search(for:)``:

```swift
switch scores.search(for: 30) {
case .found(let idx):
    print("30 found at index \(idx)")
case .notFound(let idx):
    print("30 not in array; would be inserted at index \(idx)")
}
```

### Iterating Over the Sorted Elements

Because `OrderedArray` conforms to `RandomAccessCollection`, you can use any standard Swift iteration pattern and always receive elements in sorted order:

```swift
for score in scores {
    print(score)  // 1, 7, 23, 42, 55, 100
}

let topThree = scores.suffix(3)       // [42, 55, 100]
let doubled  = scores.map { $0 * 2 }  // [2, 14, 46, 84, 110, 200]
```

## Topics

### Initializers

- ``OrderedArray/init(areInIncreasingOrder:)``

### Invariant

- ``OrderedArray/areInIncreasingOrder``
- ``OrderedArray/checkInvariant()``
- ``OrderedArray/withInvariantCheckingTemporarilyDisabled(_:)``

### Finding Elements

- ``OrderedArray/search(for:)``
- ``OrderedArray/firstIndex(of:)``

### Mutating the OrderedArray

- ``OrderedArray/insert(_:)``
- ``OrderedArray/insert(contentsOf:)``
- ``OrderedArray/remove(at:)``
- ``OrderedArray/removeAll(keepingCapacity:)``
- ``OrderedArray/removeFirstOccurrence(of:)``
- ``OrderedArray/remove(contentsOf:)``
- ``OrderedArray/removeAll(where:)``

### Unsafe Operations

- ``OrderedArray/unsafelyInsert(_:at:)``
- ``OrderedArray/subscript(unsafe:)``
