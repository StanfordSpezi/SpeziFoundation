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
struct RuntimeEnvironmentTests {
    @Test
    func sandbox() {
        #if os(macOS) || targetEnvironment(macCatalyst)
        // by default, the tests aren't sandboxed on macOS
        #expect(!ProcessInfo.isRunningInSandbox)
        #else
        #expect(ProcessInfo.isRunningInSandbox)
        #endif
    }
    
    #if !os(Linux)
    @Test
    func runningInXCTest() {
        #expect(ProcessInfo.isRunningInXCTest)
    }
    #else
    @Test(.disabled("Skipped on Linux: runningInXCTest() calls NSClassFromString() which uses the Objective-C runtime."))
    func runningInXCTest() { }
    #endif
}
