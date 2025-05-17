//
// This source file is part of the Stanford Spezi open-source project
//
// SPDX-FileCopyrightText: 2024 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import RuntimeAssertionsTesting
import SpeziFoundation
import Testing


struct OrderedArrayTests {
    @Test
    func orderedArray() {
        var array = OrderedArray<Int> { $0 < $1 }
        array.insert(12)
        #expect(array.elementsEqual([12]))
        array.insert(14)
        #expect(array.elementsEqual([12, 14]))
        array.insert(7)
        #expect(array.elementsEqual([7, 12, 14]))
        array.insert(contentsOf: [0, 1, 8, 13, 19])
        #expect(array.elementsEqual([0, 1, 7, 8, 12, 13, 14, 19]))
        array.insert(7)
        #expect(array.elementsEqual([0, 1, 7, 7, 8, 12, 13, 14, 19]))
        array.removeFirstOccurrence(of: 8)
        #expect(array.elementsEqual([0, 1, 7, 7, 12, 13, 14, 19]))
        #expect(array.contains(12))
        #expect(array.search(for: 7) == .found(2))
        #expect(array.search(for: 8) == .notFound(4))
    }
    
    
    @Test
    func orderedArray2() {
        var array = OrderedArray<Int> { $0 > $1 }
        array.insert(contentsOf: (0..<10_000).map { _ in Int.random(in: Int.min...Int.max) })
        #expect(array.isSorted(by: { $0 > $1 }))
    }
    
    
    @Test
    func findElement() {
        var array = OrderedArray<Int> { $0 < $1 }
        array.insert(contentsOf: [0, 5, 2, 9, 5, 2, 7, 6, 5, 3, 2, 1])
        #expect(array.elementsEqual([0, 1, 2, 2, 2, 3, 5, 5, 5, 6, 7, 9]))
        // we type-erase the concrete type, in order to test the _customIndexOfEquatableElement and _customContainsEquatableElement implementations
        func imp(_ col: any Collection<Int>) {
            #expect(col.contains(0))
            #expect(col.contains(1))
            #expect(col.contains(3))
            #expect(!col.contains(4))
            #expect(col.contains(5))
            #expect(col.contains(6))
            #expect(col.contains(7))
            #expect(!col.contains(8))
            #expect(col.contains(9))
            #expect(!col.contains(10))
            
            // swiftlint:disable contains_over_first_not_nil
            #expect(col.firstIndex(of: 0) != nil)
            #expect(col.firstIndex(of: 1) != nil)
            #expect(col.firstIndex(of: 3) != nil)
            #expect(col.firstIndex(of: 4) == nil)
            #expect(col.firstIndex(of: 5) != nil)
            #expect(col.firstIndex(of: 6) != nil)
            #expect(col.firstIndex(of: 7) != nil)
            #expect(col.firstIndex(of: 8) == nil)
            #expect(col.firstIndex(of: 9) != nil)
            #expect(col.firstIndex(of: 10) == nil)
            // swiftlint:enable contains_over_first_not_nil
        }
        imp(array)
    }
    
    
    @Test
    func elementRemoval() throws {
        var array = OrderedArray<Int> { $0 < $1 }
        array.insert(contentsOf: [0, 5, 2, 9, 5, 2, 7, 6, 5, 3, 2, 1])
        #expect(array.elementsEqual([0, 1, 2, 2, 2, 3, 5, 5, 5, 6, 7, 9]))
        array.removeFirstOccurrence(of: 2)
        #expect(array.elementsEqual([0, 1, 2, 2, 3, 5, 5, 5, 6, 7, 9]))
        array.remove(at: try #require(array.firstIndex(of: 5)))
        #expect(array.elementsEqual([0, 1, 2, 2, 3, 5, 5, 6, 7, 9]))
        array.removeAll(where: { $0 < 4 })
        #expect(array.elementsEqual([5, 5, 6, 7, 9]))
        array.removeFirstOccurrence(of: 2)
        #expect(array.elementsEqual([5, 5, 6, 7, 9]))
        array.remove(contentsOf: [5, 6])
        #expect(array.elementsEqual([7, 9]))
        let capacity = array.capacity
        array.removeAll(keepingCapacity: true)
        #expect(array.isEmpty)
        #expect(array.capacity == capacity)
    }
    
    @Test
    func unsafeOperations() throws {
        var array = OrderedArray<Int> { $0 < $1 }
        array.insert(12)
        array.insert(5)
        #expect(array.elementsEqual([5, 12]))
        
        expectRuntimePrecondition {
            array.unsafelyInsert(7, at: array.startIndex)
            // since the preconditionFailure call was caught, rather than it terminating the program, we need to undo the change
        }
        #expect(array.elementsEqual([7, 5, 12]))
        array.remove(at: array.startIndex)
        #expect(array.elementsEqual([5, 12]))
        
        expectRuntimePrecondition {
            array[unsafe: array.startIndex] += 12
        }
        #expect(array.elementsEqual([17, 12]))
        // since the preconditionFailure call was caught, rather than it terminating the program, we need to undo the change
        array.remove(at: array.startIndex)
        #expect(array.elementsEqual([12]))
    }
}
