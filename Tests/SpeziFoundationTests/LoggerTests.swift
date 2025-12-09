//
// This source file is part of the Stanford Spezi open-source project
//
// SPDX-FileCopyrightText: 2025 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import SpeziFoundation
import Testing
#if canImport(OSLog)
import OSLog
#else
import Logging
#endif

@Suite
struct LoggerTests {
    @Test
    func loggerUnderlyingType() async throws {
        let logger = Logger(subsystem: "test", category: "unit")
        #if canImport(os)
        #expect(type(of: logger) == os.Logger.self, "Should use os.Logger on Apple platforms")
        #else
        #expect(type(of: logger) == Logging.Logger.self, "Should use swift-log Logger on non-Apple platforms")
        #endif
    }
}
