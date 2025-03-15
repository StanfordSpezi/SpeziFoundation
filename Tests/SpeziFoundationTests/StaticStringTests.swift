//
// This source file is part of the Stanford Spezi open-source project
//
// SPDX-FileCopyrightText: 2025 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

// swiftlint:disable identical_operands

import Foundation
@testable import SpeziFoundation
import Testing


/// helper function to get a `StaticString` from a literal without having to write `as StaticString` everywhere.
@_transparent
private func s(_ string: StaticString) -> StaticString {
    string
}

struct StaticStringTests {
    @Test
    func equality() {
        #expect(s("abc") == s("abc"))
        #expect(s("def") == s("def"))
        #expect(s("abc") != s("def"))
    }
    
    @Test
    func hashing() {
        #expect(s("abc").hashValue == s("abc").hashValue)
        #expect(s("def").hashValue == s("def").hashValue)
        #expect(s("abc").hashValue != s("def").hashValue)
    }
}
