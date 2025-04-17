//
// This source file is part of the Stanford Spezi open-source project
//
// SPDX-FileCopyrightText: 2025 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import Foundation
import SpeziFoundation
import Testing


@Suite
struct SequenceExtensions {
    @Test
    func mapIntoSet() {
        #expect([0, 1, 2, 3, 4].mapIntoSet { $0 * 2 } == [0, 2, 4, 6, 8])
        #expect([0, 1, 2, 3, 4].mapIntoSet { $0 / 2 } == [0, 1, 2])
    }
    
    @Test
    func compactMapIntoSet() {
        #expect([0, 1, 2, 3, 4].compactMapIntoSet { $0.isMultiple(of: 2) ? $0 * 2 : nil } == [0, 4, 8])
        #expect([0, 1, 2, 3, 4].compactMapIntoSet { $0.isMultiple(of: 2) ? $0 / 2 : nil } == [0, 1, 2])
    }
    
    @Test
    func flatMapIntoSet() {
        struct Person {
            let name: String
            let petNames: [String]
        }
        let lukas = Person(name: "Lukas", petNames: ["Snugglebug", "Tofu", "Clover", "Muffin"])
        let paul = Person(name: "Paul", petNames: ["Pudding", "Sprout", "Clover"])
        #expect([paul, lukas].flatMapIntoSet(\.petNames) == ["Snugglebug", "Tofu", "Clover", "Pudding", "Muffin", "Sprout"])
    }
    
    @Test
    func removeAtIndices() {
        var array = Array(0...9)
        array.remove(at: [0, 7, 5, 2])
        #expect(array == [1, 3, 4, 6, 8, 9])
        
        array = Array(0...9)
        array.remove(at: [0, 7, 5, 2] as IndexSet)
        #expect(array == [1, 3, 4, 6, 8, 9])
    }
    
    @Test
    func asyncReduce() async throws {
        let names = ["Paul", "Lukas"]
        let reduced = try await names.reduce(0) { acc, name in
            try await Task.sleep(for: .seconds(0.2)) // best i could think of to get some trivial async-ness in here...
            return acc + name.count
        }
        #expect(reduced == 9)
    }
    
    @Test
    func asyncReduceInto() async throws {
        let names = ["Paul", "Lukas"]
        let reduced = try await names.reduce(into: 0) { acc, name in
            try await Task.sleep(for: .seconds(0.2)) // best i could think of to get some trivial async-ness in here...
            acc += name.count
        }
        #expect(reduced == 9)
    }
}
