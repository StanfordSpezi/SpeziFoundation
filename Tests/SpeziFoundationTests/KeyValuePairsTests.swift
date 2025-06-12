//
// This source file is part of the Stanford Spezi open-source project
//
// SPDX-FileCopyrightText: 2025 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//


@testable import SpeziFoundation
import Testing
import Foundation


private func AssertEqual<Key: Hashable, Value: Equatable>(
    _ lhs: KeyValuePairs<Key, Value>,
    _ rhs: KeyValuePairs<Key, Value>,
    _ sourceLocation: SourceLocation = #_sourceLocation,
    line: UInt = #line
) throws {
    let duplicateEntriesError = NSError(domain: "edu.stanford.spezi", code: 0, userInfo: [
        NSLocalizedDescriptionKey: "Duplicate keys!"
    ])
    let lhs = try Dictionary(lhs.lazy.map { ($0, $1) }, uniquingKeysWith: { _, _ in throw duplicateEntriesError })
    let rhs = try Dictionary(rhs.lazy.map { ($0, $1) }, uniquingKeysWith: { _, _ in throw duplicateEntriesError })
    if lhs != rhs {
        Issue.record("'\(lhs)' was not equal to '\(rhs)'", sourceLocation: sourceLocation)
    }
}


@Suite("Key Value Pair Tests")
struct KeyValuePairsTests {
    @Test
    func testCreateKeyValuePairsFromSequence() throws {
        let sequence: some Sequence<(String, Int)> = [
            ("A", 1), ("B", 2), ("C", 3), ("D", 4), ("E", 5), ("F", 6)
        ]
        try AssertEqual(
            KeyValuePairs(sequence),
            ["A": 1, "B": 2, "C": 3, "D": 4, "E": 5, "F": 6]
        )
    }
    
    @Test
    func testCreateKeyValuePairsFromDictionary() throws {
        let dictionary = [
            "A": 1, "B": 2, "C": 3, "D": 4, "E": 5, "F": 6
        ]
        try AssertEqual(
            KeyValuePairs(dictionary.lazy.map { ($0, $1) }),
            ["A": 1, "B": 2, "C": 3, "D": 4, "E": 5, "F": 6]
        )
    }
}
