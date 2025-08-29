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
        let compressed = try input.compressed(using: Zlib.self)
        #expect(input.count == 14_000)
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
}
