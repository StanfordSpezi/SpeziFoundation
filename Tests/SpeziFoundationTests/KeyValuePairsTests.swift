//
// This source file is part of the Stanford Spezi open-source project
//
// SPDX-FileCopyrightText: 2025 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//


import SpeziFoundation
import XCTest


private func XCTAssertEqual<Key: Hashable, Value: Equatable>(
    _ lhs: KeyValuePairs<Key, Value>,
    _ rhs: KeyValuePairs<Key, Value>,
    file: StaticString = #filePath,
    line: UInt = #line
) throws {
    let duplicateEntriesError = NSError(domain: "edu.stanford.spezi", code: 0, userInfo: [
        NSLocalizedDescriptionKey: "Duplicate keys!"
    ])
    let lhs = try Dictionary(lhs.lazy.map { ($0, $1) }, uniquingKeysWith: { _, _ in throw duplicateEntriesError })
    let rhs = try Dictionary(rhs.lazy.map { ($0, $1) }, uniquingKeysWith: { _, _ in throw duplicateEntriesError })
    if lhs != rhs {
        XCTFail("'\(lhs)' was not equal to '\(rhs)'", file: file, line: line)
    }
}


final class KeyValuePairsTests: XCTestCase {
    func testCreateKeyValuePairsFromSequence() throws {
        let sequence: some Sequence<(String, Int)> = [
            ("A", 1), ("B", 2), ("C", 3), ("D", 4), ("E", 5), ("F", 6)
        ]
        try XCTAssertEqual(
            KeyValuePairs(sequence),
            ["A": 1, "B": 2, "C": 3, "D": 4, "E": 5, "F": 6]
        )
    }
    
    func testCreateKeyValuePairsFromDictionary() throws {
        let dictionary = [
            "A": 1, "B": 2, "C": 3, "D": 4, "E": 5, "F": 6
        ]
        try XCTAssertEqual(
            KeyValuePairs(dictionary.lazy.map { ($0, $1) }),
            ["A": 1, "B": 2, "C": 3, "D": 4, "E": 5, "F": 6]
        )
    }
}
