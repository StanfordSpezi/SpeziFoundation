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

/// helper function to get a `StaticString` from a literal without having to write `as StaticString` everywhere.
@_transparent
private func s2(_ string: StaticScalar) -> StaticString {
    string.value
}


struct StaticStringTests {
    @Test
    func equality() {
        #expect(s2("a") == s2("a"))
        #expect(s2("b") == s2("b"))
        #expect(s2("a") != s2("b"))
        #expect(s2("🚀") == s2("🚀"))
        #expect(s2("🚀") != s("🚀"))
        #expect(s("🚀") == s("🚀"))
        #expect(s("abc") == s("abc"))
        #expect(s("def") == s("def"))
        #expect(s("abc") != s("def"))
        #expect(s("a") != s2("a"))
    }
    
    @Test
    func hashing() {
        #expect(s("a").hashValue == s("a").hashValue)
        #expect(s("b").hashValue == s("b").hashValue)
        #expect(s("a").hashValue != s("b").hashValue)
        #expect(s("🚀").hashValue == s("🚀").hashValue)
        #expect(s("🚀").hashValue != s2("🚀").hashValue)
        #expect(s2("🚀").hashValue == s2("🚀").hashValue)
        #expect(s("abc").hashValue == s("abc").hashValue)
        #expect(s("def").hashValue == s("def").hashValue)
        #expect(s("abc").hashValue != s("def").hashValue)
        #expect(s("a").hashValue != s2("a").hashValue)
        #expect(s2("a").hashValue == s2("a").hashValue)
    }
}


private struct StaticScalar: ExpressibleByUnicodeScalarLiteral {
    typealias UnicodeScalarLiteralType = StaticString
    let value: StaticString
    init(unicodeScalarLiteral value: StaticString) {
        self.value = value
    }
}
