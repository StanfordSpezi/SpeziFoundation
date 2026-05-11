//
// This source file is part of the SpeziFoundation open source project
//
// SPDX-FileCopyrightText: 2026 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

#if os(macOS) && canImport(SpeziFoundationMacros) // macro tests can only be run on the host machine
import SpeziFoundationMacrosImpl
import SwiftSyntaxMacroExpansion
import SwiftSyntaxMacros
import SwiftSyntaxMacrosGenericTestSupport
import SwiftSyntaxMacrosTestSupport
import Testing

let testMacrosSpecs: [String: MacroSpec] = [
    "url": MacroSpec(type: URLMacro.self)
]


@Suite
struct URLMacroTests {
    @Test
    func valid() {
        assertMacroExpansion(
            """
            let url = #url("https://stanford.edu")
            """,
            expandedSource:
            """
            let url = try! Foundation.URL("https://stanford.edu", strategy: .url)
            """,
            macroSpecs: testMacrosSpecs,
            failureHandler: { Issue.record("\($0.message)") }
        )
    }
    
    
    @Test
    func invalidUrl() {
        assertMacroExpansion(
            """
            let url = #url("https:/stanford.edu")
            """,
            expandedSource:
            """
            let url = #url("https:/stanford.edu")
            """,
            diagnostics: [
                DiagnosticSpec(
                    message: "Invalid URL literal",
                    line: 1,
                    column: 11
                )
            ],
            macroSpecs: testMacrosSpecs,
            failureHandler: { Issue.record("\($0.message)") }
        )
    }
    
    @Test
    func invalidInput0() {
        assertMacroExpansion(
            """
            let url = #url(123)
            """,
            expandedSource:
            """
            let url = #url(123)
            """,
            diagnostics: [
                DiagnosticSpec(
                    message: "Input must be a String literal",
                    line: 1,
                    column: 11
                )
            ],
            macroSpecs: testMacrosSpecs,
            failureHandler: { Issue.record("\($0.message)") }
        )
    }
    
    @Test
    func invalidInput1() {
        assertMacroExpansion(
            """
            let value = "https://stanford.edu"
            let url = #url(value)
            """,
            expandedSource:
            """
            let value = "https://stanford.edu"
            let url = #url(value)
            """,
            diagnostics: [
                DiagnosticSpec(
                    message: "Input must be a String literal",
                    line: 2,
                    column: 11
                )
            ],
            macroSpecs: testMacrosSpecs,
            failureHandler: { Issue.record("\($0.message)") }
        )
    }
    
    @Test
    func invalidInput2() {
        assertMacroExpansion(
            #"""
            let host = "stanford"
            let url = #url("https://\(host).edu")
            """#,
            expandedSource:
            #"""
            let host = "stanford"
            let url = #url("https://\(host).edu")
            """#,
            diagnostics: [
                DiagnosticSpec(
                    message: "Input String literal isn't allowed to contain interpolations",
                    line: 2,
                    column: 11
                )
            ],
            macroSpecs: testMacrosSpecs,
            failureHandler: { Issue.record("\($0.message)") }
        )
    }
}
#endif
