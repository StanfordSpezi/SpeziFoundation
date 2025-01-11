//
// This source file is part of the Stanford Spezi open-source project
//
// SPDX-FileCopyrightText: 2024 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import SpeziFoundation
import XCTest


final class OrderedArrayTests: XCTestCase {
    func testOrderedArray() {
        var array = OrderedArray<Int> { $0 < $1 }
        array.insert(12)
        XCTAssertTrue(array.elementsEqual([12]))
        array.insert(14)
        XCTAssertTrue(array.elementsEqual([12, 14]))
        array.insert(7)
        XCTAssertTrue(array.elementsEqual([7, 12, 14]))
        array.insert(contentsOf: [0, 1, 8, 13, 19])
        XCTAssertTrue(array.elementsEqual([0, 1, 7, 8, 12, 13, 14, 19]))
        array.insert(7)
        XCTAssertTrue(array.elementsEqual([0, 1, 7, 7, 8, 12, 13, 14, 19]))
        array.removeFirstOccurrence(of: 8)
        XCTAssertTrue(array.elementsEqual([0, 1, 7, 7, 12, 13, 14, 19]))
        XCTAssertTrue(array.contains(12))
        XCTAssertEqual(array.search(for: 7), .found(2))
        XCTAssertEqual(array.search(for: 8), .notFound(4))
    }
    
    
    func testOrderedArray2() {
        var array = OrderedArray<Int> { $0 > $1 }
        array.insert(contentsOf: (0..<10_000).map { _ in Int.random(in: Int.min...Int.max) })
        XCTAssertTrue(array.isSorted(by: { $0 > $1 }))
    }
    
    
    func testFindElement() {
        var array = OrderedArray<Int> { $0 < $1 }
        array.insert(contentsOf: [0, 5, 2, 9, 5, 2, 7, 6, 5, 3, 2, 1])
        XCTAssertTrue(array.elementsEqual([0, 1, 2, 2, 2, 3, 5, 5, 5, 6, 7, 9]))
        // we type-erase the concrete type, in order to test the _customIndexOfEquatableElement and _customContainsEquatableElement implementations
        func imp(_ col: some Collection<Int>) {
            XCTAssertTrue(col.contains(0))
            XCTAssertTrue(col.contains(1))
            XCTAssertTrue(col.contains(3))
            XCTAssertFalse(col.contains(4))
            XCTAssertTrue(col.contains(5))
            XCTAssertTrue(col.contains(6))
            XCTAssertTrue(col.contains(7))
            XCTAssertFalse(col.contains(8))
            XCTAssertTrue(col.contains(9))
            XCTAssertFalse(col.contains(10))
            
            XCTAssertNotNil(col.firstIndex(of: 0))
            XCTAssertNotNil(col.firstIndex(of: 1))
            XCTAssertNotNil(col.firstIndex(of: 3))
            XCTAssertNil(col.firstIndex(of: 4))
            XCTAssertNotNil(col.firstIndex(of: 5))
            XCTAssertNotNil(col.firstIndex(of: 6))
            XCTAssertNotNil(col.firstIndex(of: 7))
            XCTAssertNil(col.firstIndex(of: 8))
            XCTAssertNotNil(col.firstIndex(of: 9))
            XCTAssertNil(col.firstIndex(of: 10))
        }
        imp(array)
    }
    
    
    func testElementRemoval() throws {
        var array = OrderedArray<Int> { $0 < $1 }
        array.insert(contentsOf: [0, 5, 2, 9, 5, 2, 7, 6, 5, 3, 2, 1])
        XCTAssertTrue(array.elementsEqual([0, 1, 2, 2, 2, 3, 5, 5, 5, 6, 7, 9]))
        array.removeFirstOccurrence(of: 2)
        XCTAssertTrue(array.elementsEqual([0, 1, 2, 2, 3, 5, 5, 5, 6, 7, 9]))
        array.remove(at: try XCTUnwrap(array.firstIndex(of: 5)))
        XCTAssertTrue(array.elementsEqual([0, 1, 2, 2, 3, 5, 5, 6, 7, 9]))
        array.removeAll(where: { $0 < 4 })
        XCTAssertTrue(array.elementsEqual([5, 5, 6, 7, 9]))
        array.removeFirstOccurrence(of: 2)
        XCTAssertTrue(array.elementsEqual([5, 5, 6, 7, 9]))
        array.remove(contentsOf: [5, 6])
        XCTAssertTrue(array.elementsEqual([7, 9]))
        let capacity = array.capacity
        array.removeAll(keepingCapacity: true)
        XCTAssertTrue(array.isEmpty)
        XCTAssertEqual(array.capacity, array.capacity)
    }
}
