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


struct VersionTests {
    @Test
    func parsing() throws {
        #expect(Version(1, 0, 0) == "1.0.0")
        #expect(Version(1, 1, 1) == "1.1.1")
        #expect(Version(1, 2, 3) == "1.2.3")
        #expect(Version(1, 2, 3) != "1.2.3-beta")
        #expect(Version(1, 2, 3) != "1.2.3-beta.1")
        #expect(Version(1, 2, 3, buildMetadata: ["abc"]) == "1.2.3")
        #expect(Version.init("a.b.c") == nil) // swiftlint:disable:this explicit_init
        #expect(Version.init("-1.2.3") == nil) // swiftlint:disable:this explicit_init
    }
    
    
    @Test
    func compare() throws {
        #expect(Version(1, 2, 3) == Version(1, 2, 3))
        #expect(Version(1, 2, 3) < Version(1, 2, 4))
        #expect(Version(1, 2, 3) < Version(1, 3, 3))
        #expect(Version(1, 2, 3) < Version(2, 2, 3))
        #expect(!(Version(2, 2, 3) < Version(2, 2, 3)))
        #expect(!(Version(2, 3, 3) < Version(2, 2, 3)))
        #expect(Version(2, 3, 3) > Version(2, 2, 3))
        #expect(Version(2, 3, 3) >= Version(2, 2, 3))
        
        #expect(Version(1, 0, 0) < Version(2, 0, 0))
        #expect(Version(2, 0, 0) < Version(2, 1, 0))
        #expect(Version(2, 1, 0) < Version(2, 1, 1))
        #expect(Version(1, 0, 1) > Version(1, 0, 0))
        #expect(!(Version(1, 0, 0) > Version(1, 0, 0)))
        #expect(Version(1, 0, 0) >= Version(1, 0, 0))
        #expect(Version(1, 0, 0) > Version(0, 0, 1))
        #expect(Version(0, 0, 1) < Version(1, 0, 0))
        #expect(Version(0, 1, 0) < Version(1, 0, 0))
        #expect(Version(0, 1, 1) < Version(1, 0, 0))
        #expect(Version(0, 0, 1) >= Version(0, 0, 1))
        #expect(Version(0, 0, 2) >= Version(0, 0, 1))
        #expect(Version(0, 1, 0) > Version(0, 0, 1))
        #expect(Version(0, 1, 0) >= Version(0, 0, 1))
        #expect(Version(3, 1, 0) > Version(2, 1, 1))
        #expect(Version(3, 1, 0) >= Version(2, 1, 1))
        #expect(Version(3, 1, 5) > Version(2, 1, 1))
        #expect(Version(3, 1, 5) >= Version(2, 1, 1))
        
        #expect(try #require(Version("1.0.0-alpha")) < Version(1, 0, 0))
        
        #expect(try #require(Version("1.2.3-beta.1")) < #require(Version("1.2.3-beta.2")))
        #expect(try #require(Version("1.2.3-beta.1")) < #require(Version("1.2.3-beta.2+123")))
        #expect(try #require(Version("1.2.3-beta.1+123")) < #require(Version("1.2.3-beta.2")))
        #expect(try #require(Version("1.2.3-beta.1")) == #require(Version("1.2.3-beta.1")))
        #expect(try #require(Version("1.2.3-beta.3")) > #require(Version("1.2.3-beta.1")))
        #expect(try #require(Version("1.2.3-beta.3")) > #require(Version("1.2.3-alpha.3")))
        #expect(try #require(Version("1.2.3-alpha.1.2")) == #require(Version("1.2.3-alpha.1.2")))
        #expect(try #require(Version("1.2.3-beta.1.2")) != #require(Version("1.2.3-alpha.1.2")))
        #expect(try #require(Version("1.2.3-alpha.1.2")) >= #require(Version("1.2.3-alpha.1.2")))
        #expect(try #require(Version("1.2.3-alpha")) < #require(Version("1.2.3-alpha.1")))
        #expect(try #require(Version("1.2.3-alpha")) < #require(Version("1.2.3-alpha.1.2")))
        #expect(try #require(Version("1.2.3-alpha")) > #require(Version("1.2.3-1")))
        #expect(try #require(Version("1.2.3-alpha.1")) < #require(Version("1.2.3-alpha.a")))
        #expect(!(try #require(Version("1.2.3-alpha.a")) < #require(Version("1.2.3-alpha.1"))))
    }
    
    
    @Test
    func coding() throws {
        let versions: [Version] = [
            "1.0.0",
            "1.1.1",
            "1.2.3",
            "1.2.3-beta",
            "1.2.3-beta.1",
            "1.2.3-alpha.1.2",
            "0.0.1-zlorb.12+1234"
        ]
        for version in versions {
            let encoded = try JSONEncoder().encode(version)
            let decoded = try JSONDecoder().decode(Version.self, from: encoded)
            #expect(decoded == version)
        }
        let invalidEncoding = try JSONEncoder().encode("1.2.-3")
        #expect(throws: DecodingError.self) {
            try JSONDecoder().decode(Version.self, from: invalidEncoding)
        }
    }
}

// swiftlint:enable identical_operands
