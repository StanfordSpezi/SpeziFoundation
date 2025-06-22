//
// This source file is part of the Stanford Spezi open-source project
//
// SPDX-FileCopyrightText: 2024 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import SpeziFoundation
import XCTest


final class CollectionBuildersTests: XCTestCase {
    private func _imp<C: RangeReplaceableCollection>(
        _: C.Type,
        expected: C,
        @RangeReplaceableCollectionBuilder<C> _ make: () -> C,
        file: StaticString = #filePath,
        line: UInt = #line
    ) where C: Equatable {
        let collection = make()
        XCTAssertEqual(collection, expected, file: file, line: line)
    }
    
    
    private func mightThrow<T>(_ value: T) throws -> T {
        value
    }
    
    
    func testArrayBuilder() {
        _imp([Int].self, expected: [1, 2, 3, 4, 5, 7, 8, 9, 52, 41]) {
            1
            2
            [3, 4, 5]
            if Date() < Date.distantPast {
                6
            } else {
                [7, 8]
                9
            }
            if let value = Int?.some(52) {
                value
            }
            if #available(iOS 17, macOS 14, *) {
                41
            }
        }
        XCTAssertEqual(Array<Int> {}, []) // swiftlint:disable:this syntactic_sugar
    }
    
    func testStringBuilder() {
        let greet = {
            "Hello, \($0 as String) 🚀\n"
        }
        _imp(
            String.self,
            expected: """
            Hello, Lukas 🚀
            Hello, Lukas 🚀
            Hello, Paul 🚀
            Hello, Paul 🚀
            Hello, World 🚀
            abc
            we're in the present day
            it's fine
            def
            """
        ) {
            for name in ["Lukas", "Paul"] {
                greet(name)
                greet(name)
            }
            greet("World")
            "abc\n"
            if Date() < .distantFuture {
                "we're in the present day\n"
            } else {
                "we're in the future, babyyy\n"
            }
            if let name = [String]().randomElement() {
                name
            }
            if Date() > .distantFuture {
                "concerning\n"
            } else {
                "it's fine\n"
            }
            ("def"[...] as Substring)
        }
    }
    
    
    func testSetBuilder() {
        XCTAssertEqual(Set<Int> {}, Set<Int>())
        let greet = {
            "Hello, \($0 as String) 🚀"
        }
        let set = Set<String> {
            for name in ["Lukas", "Paul"] {
                greet(name)
                greet(name)
            }
            greet("World")
            "abc"
            if Date() < .distantFuture {
                "we're in the present day"
            } else {
                "we're in the future, babyyy"
            }
            if Date() > .distantFuture {
                "concerning"
            } else {
                "it's fine"
            }
            if let name = ["Jakob"].randomElement() {
                name
            }
            if let name = [String]().randomElement() {
                name
            }
            if let abc = [String]?.some(["a", "b", "c"]) {
                abc
            }
            if true {
                ["a", "b", "c"]
            }
        }
        let expected: Set<String> = [
            "Hello, Lukas 🚀",
            "Hello, Paul 🚀",
            "Hello, World 🚀",
            "abc",
            "we're in the present day",
            "Jakob",
            "it's fine",
            "a",
            "b",
            "c"
        ]
        XCTAssertEqual(set, expected)
    }
    
    
    func testArrayBuilderThrowing() throws {
        let array1: [Int] = Array {
            1
            2
            3
        }
        let array2: [Int] = try Array {
            1
            try mightThrow(2)
            3
        }
        XCTAssertEqual(array1, [1, 2, 3])
        XCTAssertEqual(array2, [1, 2, 3])
    }
}
