//
// This source file is part of the Stanford Spezi open-source project
//
// SPDX-FileCopyrightText: 2025 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import SpeziFoundation
import XCTest


final class SequenceExtensionTests: XCTestCase {
    func testMapIntoSet() {
        XCTAssertEqual([0, 1, 2, 3, 4].mapIntoSet { $0 * 2 }, [0, 2, 4, 6, 8])
        XCTAssertEqual([0, 1, 2, 3, 4].mapIntoSet { $0 / 2 }, [0, 1, 2])
    }
    
    
    func testRemoveAtIndices() {
        var array = Array(0...9)
        array.remove(at: [0, 7, 5, 2])
        XCTAssertEqual(array, [1, 3, 4, 6, 8, 9])
        
        array = Array(0...9)
        array.remove(at: [0, 7, 5, 2] as IndexSet)
        XCTAssertEqual(array, [1, 3, 4, 6, 8, 9])
    }
}