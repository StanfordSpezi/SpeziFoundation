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
struct CompressionAlgorithmTests {
    @Test
    func zlib() throws {
        let input = try #require(String(repeating: "Hello Spezi :)", count: 1000).data(using: .utf8))
        #expect(input.count == 14_000)
        let compressed = try input.compressed(using: Zlib.self)
        #expect(compressed.count == 70)
        #expect(compressed == Data([
            120, 218, 237, 199, 49, 13, 0, 32, 12, 0, 48, 43, 188, 88, 64, 193, 126, 52, 236,
            32, 89, 2, 55, 234, 241, 192, 221, 126, 141, 172, 218, 109, 158, 188, 171, 141,
            30, 102, 102, 102, 102, 102, 102, 102, 102, 102, 102, 102, 102, 102, 102, 102, 102,
            102, 102, 102, 102, 102, 102, 102, 102, 102, 102, 102, 95, 123, 147, 122, 25, 223
        ]))
        let decompressed = try compressed.decompressed(using: Zlib.self)
        #expect(decompressed == input)
    }
    
    
    @Test
    func zstd() throws {
        let input = try #require(String(repeating: "Hello Spezi :)", count: 1000).data(using: .utf8))
        #expect(input.count == 14_000)
        let compressed = try input.compressed(using: Zstd.self)
        print(Array(compressed))
        #expect(compressed.count == 32)
        #expect(compressed == Data([
            40, 181, 47, 253, 96, 176, 53, 181, 0, 0, 112, 72, 101, 108, 108, 111,
            32, 83, 112, 101, 122, 105, 32, 58, 41, 1, 0, 159, 54, 248, 169, 4
        ]))
        let decompressed = try compressed.decompressed(using: Zstd.self)
        #expect((decompressed == input) as Bool)
    }
}
