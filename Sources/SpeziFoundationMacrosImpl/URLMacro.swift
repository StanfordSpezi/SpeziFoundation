//
// This source file is part of the Stanford Spezi open-source project
//
// SPDX-FileCopyrightText: 2026 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import struct Foundation.URL
import SwiftDiagnostics
import SwiftSyntax
import SwiftSyntaxMacros


/// The `#url` macro.
public struct URLMacro: ExpressionMacro {
    fileprivate struct ErrorDiagnosticMessage: DiagnosticMessage {
        enum ID: String {
            case notAStringLiteral
            case containsInterpolation
            case invalidUrlValue
        }
        
        let message: String
        let diagnosticID: MessageID
        let severity: DiagnosticSeverity
        
        init(message: String, id: ID, severity: DiagnosticSeverity) {
            self.message = message
            self.diagnosticID = MessageID(domain: "SpeziFoundation.URLMacro", id: id.rawValue)
            self.severity = severity
        }
    }
    
    
    public static func expansion(
        of node: some FreestandingMacroExpansionSyntax,
        in context: some MacroExpansionContext
    ) throws -> ExprSyntax {
        guard let syntax = node.arguments.first?.expression.as(StringLiteralExprSyntax.self) else {
            throw DiagnosticsError(syntax: node, message: "Input must be a String literal", id: .notAStringLiteral, severity: .error)
        }
        let input = try syntax.segments.reduce(into: "") { partialResult, segment in
            switch segment {
            case .stringSegment(let segment):
                partialResult.append(contentsOf: segment.content.text)
            case .expressionSegment:
                throw DiagnosticsError(
                    syntax: node,
                    message: "Input String literal isn't allowed to contain interpolations",
                    id: .containsInterpolation,
                    severity: .error
                )
            }
        }
        do {
            _ = try URL(input, strategy: .url)
            // i did some testing and it seems that we're safe in having the try! in here. it does not affect other code around the expression.
            // eg: if you do `let values = #url("https://stanford.edu").someThrowingFunction()`, it'll fail to compile and require a try before the expression.
            return "try! Foundation.URL(\(syntax), strategy: .url)"
        } catch {
            throw DiagnosticsError(syntax: node, message: "Invalid URL literal", id: .invalidUrlValue, severity: .error)
        }
    }
}


extension DiagnosticsError {
    fileprivate init(syntax: some SyntaxProtocol, message: String, id: URLMacro.ErrorDiagnosticMessage.ID, severity: DiagnosticSeverity) {
        self.init(diagnostics: [
            Diagnostic(node: syntax, message: URLMacro.ErrorDiagnosticMessage(message: message, id: id, severity: severity))
        ])
    }
}
