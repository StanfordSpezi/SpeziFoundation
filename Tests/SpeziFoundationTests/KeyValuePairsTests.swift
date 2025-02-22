//
// This source file is part of the Stanford Spezi open-source project
//
// SPDX-FileCopyrightText: 2025 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//


import SpeziFoundation
import XCTest


private func XCTAssertEqual<A: Hashable, B: Equatable>(
    _ lhs: KeyValuePairs<A, B>,
    _ rhs: KeyValuePairs<A, B>,
    file: StaticString = #filePath,
    line: UInt = #line
) {
    let lhs = Dictionary<A, B>(lhs.lazy.map { ($0, $1) }, uniquingKeysWith: { a, b in a })
    let rhs = Dictionary<A, B>(rhs.lazy.map { ($0, $1) }, uniquingKeysWith: { a, b in a })
    if lhs != rhs {
        XCTFail("'\(lhs)' was not equal to '\(rhs)'", file: file, line: line)
    }
}


final class KeyValuePairsTests: XCTestCase {
    func testCreateKeyValuePairsFromSequence() {
        let sequence: some Sequence<(String, Int)> = [
            ("A", 1), ("B", 2), ("C", 3), ("D", 4), ("E", 5), ("F", 6)
        ]
        XCTAssertEqual(
            KeyValuePairs(sequence),
            ["A": 1, "B": 2, "C": 3, "D": 4, "E": 5, "F": 6]
        )
    }
    
    func testCreateKeyValuePairsFromDictionary() {
        let dictionary = [
            "A": 1, "B": 2, "C": 3, "D": 4, "E": 5, "F": 6
        ]
        XCTAssertEqual(
            KeyValuePairs(dictionary.lazy.map { ($0, $1) }),
            ["A": 1, "B": 2, "C": 3, "D": 4, "E": 5, "F": 6]
        )
    }
}
