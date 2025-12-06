//
//  SpeziLogTests.swift
//  SpeziFoundation
//
//  Created by Philipp Nagy on 06.12.25.
//

import SpeziFoundation
import Testing
#if canImport(OSLog)
import OSLog
#else
import Logging
#endif

@Suite()
struct SpeziLogTests {
    @Test
    func speziLoggerUnderlyingType() async throws {
        let logger = SpeziLogger(subsystem: "test", category: "unit")
        #if canImport(os)
        #expect(type(of: logger) == os.Logger.self, "Should use os.Logger on Apple platforms")
        #else
        #expect(type(of: logger) == Logging.Logger.self, "Should use swift-log Logger on non-Apple platforms")
        #endif
    }
}
