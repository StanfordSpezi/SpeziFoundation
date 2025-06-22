//
// This source file is part of the Stanford Spezi open-source project
//
// SPDX-FileCopyrightText: 2025 Stanford University
//
// SPDX-License-Identifier: MIT
//

import Foundation


extension MarkdownDocument { // swiftlint:disable:this file_types_order
    /// An error that occurred when parsing markdown text.
    public struct ParseError: Error, Hashable {
        /// The parse error's kind
        public enum Kind: Hashable, Sendable {
            /// The parse input wasn't encoded as valid UTF-8 text.
            case nonUTF8Input
            /// The parser reached the end of the input file, even though it may have been expecting further content.
            case eof
            /// The parser ran into an unexpected character
            case unexpectedCharacter
            /// Some other issue.
            case other(String)
        }
        
        /// A location within a markdown document, expressed as a line and column number.
        public struct SourceLocation: Hashable, Comparable, Sendable {
            static let zero = Self(line: 0, column: 0)
            
            /// The location's line number, starting at 0.
            public let line: UInt
            /// The location's column number, i.e., its offset within its line, starting at 0.
            public let column: UInt
            
            fileprivate init(line: UInt, column: UInt) {
                self.line = line
                self.column = column
            }
            
            public static func < (lhs: Self, rhs: Self) -> Bool {
                if lhs.line < rhs.line {
                    true
                } else if lhs.line == rhs.line {
                    lhs.column < rhs.column
                } else {
                    false
                }
            }
        }
        
        /// The specific kind of error
        public let kind: Kind
        /// The source location at which the error occurred
        public let sourceLoc: SourceLocation
    }
}


struct MarkdownDocumentParser: ~Copyable {
    typealias ParseError = MarkdownDocument.ParseError
    typealias ParsedCustomElement = MarkdownDocument.ParsedCustomElement
    
    private let input: String
    private var position: String.Index
    
    init(input: String) {
        self.input = input
        self.position = input.startIndex
    }
    
    
    consuming func parse() throws(ParseError) -> MarkdownDocument {
        typealias Block = MarkdownDocument.Block
        let frontmatter = try parseFrontmatter()
        var blocks: [Block] = []
        var currentBlockText = ""
        do {
            while let currentChar {
                if currentChar == "<", isAtBeginningOfLine,
                   let element = try parseCustomElement() {
                    blocks.append(.markdown(currentBlockText))
                    currentBlockText.removeAll(keepingCapacity: true)
                    blocks.append(.customElement(element))
                } else if try skipCommentIfApplicable() {
                    // we ignore the comment
                } else {
                    currentBlockText.append(currentChar)
                    consume()
                }
            }
        } catch {
            switch error.kind {
            case .eof:
                break
            default:
                throw error
            }
        }
        blocks.append(.markdown(currentBlockText))
        blocks = blocks.compactMap { block -> Block? in
            switch block {
            case .markdown(let text):
                let trimmed = text.trimmingWhitespace()
                if trimmed.isEmpty {
                    return nil
                } else {
                    return .markdown(String(trimmed))
                }
            case .customElement:
                return block
            }
        }
        return .init(metadata: .init(frontmatter), blocks: blocks)
    }
    
    
    private mutating func parseFrontmatter() throws(ParseError) -> [String: String] {
        guard currentLine == "---" else {
            return [:]
        }
        var frontmatter: [String: String] = [:]
        consumeLine()
        while let key = try? parseIdentifier() {
            try expectAndConsume(":")
            consume(while: { $0.isWhitespace && !$0.isNewline })
            let value = currentLine ?? ""
            consumeLine()
            frontmatter[key] = String(value)
        }
        guard currentLine == "---" else {
            try emitError(.other("Unable to find end of frontmatter"))
        }
        consumeLine()
        return frontmatter
    }
    
    
    private mutating func parseIdentifier() throws(ParseError) -> String {
        var identifier = ""
        if let currentChar, currentChar.isValidIdentStart {
            identifier.append(currentChar)
            consume()
        } else {
            try emitError(.unexpectedCharacter)
        }
        while let currentChar, currentChar.isValidIdent {
            identifier.append(currentChar)
            consume()
        }
        return identifier
    }
    
    private mutating func parseInteger() -> Int? {
        let initialPos = position
        var value = 0
        let negative: Bool
        if let currentChar, currentChar == "-" {
            negative = true
            consume()
        } else {
            negative = false
        }
        let posFirstPotentialDigit = position
        while let currentChar, currentChar.isASCII, let digit = currentChar.wholeNumberValue {
            value *= 10
            value += digit
            consume()
        }
        if position == posFirstPotentialDigit {
            // if we weren't able to read any digits, we restore the initial position and return nil
            position = initialPos
            return nil
        } else {
            // otherwise, we were able to parse a value, and will return that.
            return value * (negative ? -1 : 1)
        }
    }
    
    
    private mutating func parseAttrValue() throws(ParseError) -> String {
        if currentChar == "\"" {
            try parseStringLiteral()
        } else if let ident = try? parseIdentifier() {
            ident
        } else if let value = parseInteger() {
            String(value)
        } else {
            ""
        }
    }
    
    
    private mutating func parseStringLiteral() throws(ParseError) -> String {
        try expectAndConsume("\"")
        var text = ""
        while true {
            guard let currentChar else {
                try emitError(.eof)
            }
            let isEscaped = !text.suffix { $0 == #"\"# }.count.isMultiple(of: 2)
            if currentChar == "\"" && !isEscaped {
                break
            }
            consume()
            text.append(currentChar)
        }
        try expectAndConsume("\"")
        return text
    }
    
    
    private mutating func parseCustomElement() throws(ParseError) -> ParsedCustomElement? {
        // swiftlint:disable:previous function_body_length cyclomatic_complexity
        consume(while: \.isWhitespace)
        guard currentChar == "<", let next = peek(), next.isValidIdentStart else {
            return nil
        }
        try expectAndConsume("<")
        let name = try parseIdentifier()
        var parsedElement = ParsedCustomElement(name: name)
        var elementIsClosed = false
        loop: while true {
            switch currentChar {
            case .none:
                break loop
            case ">":
                // end of opening tag
                consume()
                break loop
            case "/" where peek() == ">":
                // upcoming end of opening tag
                consume(2)
                elementIsClosed = true
                break loop
            case .some(let char) where char.isWhitespace:
                // whitespace/newlines between things
                consume()
            case .some:
                let attrName = try parseIdentifier()
                let attrValue: String
                if currentChar == "=" {
                    consume()
                    attrValue = try parseAttrValue()
                } else {
                    // attr w/out a value
                    attrValue = ""
                }
                parsedElement.attributes.append(.init(name: attrName, value: attrValue))
            }
        }
        if elementIsClosed {
            return parsedElement
        }
        if let element = _attemptToCloseCustomElement(parsedElement) {
            return element
        } else {
            while true {
                if let element = try parseCustomElement() {
                    parsedElement.content.append(.element(element))
                } else {
                    let text = String(parseElementTextContents().trimmingWhitespace())
                    if !text.isEmpty {
                        parsedElement.content.append(.text(text))
                    } else {
                        // unable to parse an element, but also no text-only content in there...
                        if let element = _attemptToCloseCustomElement(parsedElement) {
                            consume(while: \.isWhitespace)
                            return element
                        } else {
                            try emitError(.other("unable to close \(name)"))
                        }
                    }
                }
            }
        }
        try emitError(.other("Unable to find closing tag for \(parsedElement)"))
    }
    
    private mutating func _attemptToCloseCustomElement(_ element: ParsedCustomElement) -> ParsedCustomElement? {
        let possibleClosingTags = ["</>", "</\(element.name)>"]
        for tag in possibleClosingTags {
            if remainingInput.starts(with: tag) { // swiftlint:disable:this for_where
                consume(tag.count)
                return element
            }
        }
        return nil
    }
    
    
    /// Parses the `{X}` part in `<element>{X}</element>`.
    private mutating func parseElementTextContents() -> String {
        var text = ""
        while let currentChar, currentChar != "<" {
            text.append(currentChar)
            consume()
        }
        return String(text.trimmingWhitespace())
    }
    
    
    /// Parses an HTML comment starting at the current position.
    ///
    /// Since HTML doesn't support nested comments, this function in effect simply consumes all text until the next `-->` character sequence.
    ///
    /// - returns: the contents of the parsed comment, excluding the leading `<!--` and the trailing `-->`.
    ///     if no comment starts at the current position, the function returns `nil`.
    private mutating func parseComment() throws(ParseError) -> String? {
        guard remainingInput.starts(with: "<!--") else {
            return nil
        }
        consume(4)
        var commentBody = ""
        while let currentChar {
            if remainingInput.starts(with: "-->") {
                consume(3)
                return commentBody
            } else {
                commentBody.append(currentChar)
                consume()
            }
        }
        // we ran out of characters before closing the comment.
        try emitError(.other("Unterminated Comment"))
    }
    
    
    /// Skips a comment, if one starts at the current position
    ///
    /// - returns: `true` iff a comment was skipped, `false` otherwise.
    @discardableResult
    private mutating func skipCommentIfApplicable() throws(ParseError) -> Bool {
        try parseComment() != nil
    }
}

extension MarkdownDocumentParser {
    private func emitError(_ kind: ParseError.Kind) throws(ParseError) -> Never {
        throw .init(kind: kind, sourceLoc: currentSourceLoc)
    }
}


extension MarkdownDocumentParser {
    private var currentChar: Character? {
        input[safe: position]
    }
    
    private var remainingInput: Substring {
        input[position...]
    }
    
    private var currentLine: Substring? {
        remainingInput.isEmpty ? nil : remainingInput.prefix { !$0.isNewline }
    }
    
    private var isAtBeginningOfLine: Bool {
        position == input.startIndex && position < input.endIndex || input[input.index(before: position)].isNewline
    }
    
    private func peek(_ offset: Int = 1) -> Character? {
        input[safe: input.index(position, offsetBy: offset)]
    }
    
    private mutating func consume(_ count: Int = 1) {
        guard count > 0 else { // swiftlint:disable:this empty_count
            return
        }
        let newIndex = input.index(position, offsetBy: count)
        position = min(input.endIndex, newIndex)
    }
    
    private mutating func consume(while predicate: (Character) -> Bool) {
        while let currentChar, predicate(currentChar) {
            consume()
        }
    }
    
    private mutating func expectAndConsume(_ char: Character) throws(ParseError) {
        guard currentChar == char else {
            try emitError(.unexpectedCharacter)
        }
        consume()
    }
    
    /// Consumes all upcoming characters up to (and including) the next newline character.
    private mutating func consumeLine() {
        while let currentChar, !currentChar.isNewline {
            consume()
        }
        if currentChar?.isNewline == true {
            consume()
        }
    }
}


extension MarkdownDocumentParser {
    private var currentSourceLoc: ParseError.SourceLocation {
        let lineNumber = input[..<position].count(where: \.isNewline)
        let wholeCurrentLine = { () -> Substring in
            let startIdx = input[..<position].lastIndex(where: \.isNewline).map { input.index(after: $0) }
            let endIdx = remainingInput.firstIndex(where: \.isNewline)
            return switch (startIdx, endIdx) {
            case (nil, nil):
                input[...]
            case let (.some(startIdx), .none):
                input[startIdx...]
            case let (.none, .some(endIdx)):
                input[...endIdx]
            case let (.some(startIdx), .some(endIdx)):
                input[startIdx...endIdx]
            }
        }()
        return .init(
            line: UInt(lineNumber),
            column: UInt(wholeCurrentLine.distance(from: wholeCurrentLine.startIndex, to: position))
        )
    }
}


extension Character {
    fileprivate var isValidIdentStart: Bool {
        (self >= "a" && self <= "z") || (self >= "A" && self <= "Z") || self == "_"
    }
    
    fileprivate var isValidIdent: Bool {
        isValidIdentStart || (self >= "0" && self <= "9") || self == "-"
    }
}
