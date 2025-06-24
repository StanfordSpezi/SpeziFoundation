//
// This source file is part of the Stanford Spezi open-source project
//
// SPDX-FileCopyrightText: 2025 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import Foundation


/// A Markdown document
///
/// ## Topics
///
/// ### Initializers
/// - ``init(metadata:blocks:)``
/// - ``init(processing:customElementNames:)-(String,Set<String>)``
/// - ``init(processing:customElementNames:)-(Data,Set<String>)``
/// - ``init(processingContentsOf:customElementNames:)``
/// - ``ParseError``
///
/// ### Instance Properties
/// - ``metadata``
/// - ``blocks``
///
/// ### Supporting Types
/// - ``Metadata``
/// - ``Block``
public struct MarkdownDocument: Hashable, Sendable {
    /// The document's metadata.
    public var metadata: Metadata
    /// The document's content blocks.
    public var blocks: [Block]
    
    /// Creates a new Markdown document.
    public init(metadata: Metadata, blocks: [Block]) {
        self.metadata = metadata
        self.blocks = blocks
    }
    
    /// Creates a new Markdown document by processing a `String`.
    ///
    /// Note that thie doesn't perform any Markdown parsing on its own; rather, it splits up a markdown file into a sequence of blocks,
    /// each of which is either markdown content or a custom HTML element.
    ///
    /// - parameter text: The Markdown string to process.
    /// - parameter customElementNames: A `Set` of HTML tag names which should be processed into custom elements.
    ///     Any HTML tags encountered that aren't specified in the set will be treated as if they were part of the normal markdown text.
    public init(processing text: String, customElementNames: Set<String> = []) throws(ParseError) {
        let parser = Parser(input: text, customElementNames: customElementNames)
        self = try parser.parse()
    }
    
    /// Creates a new Markdown document by processing a `Data` object.
    ///
    /// Note that thie doesn't perform any Markdown parsing on its own; rather, it splits up a markdown file into a sequence of blocks,
    /// each of which is either markdown content or a custom HTML element.
    ///
    /// - parameter data: The Markdown data to process.
    /// - parameter customElementNames: A `Set` of HTML tag names which should be processed into custom elements.
    ///     Any HTML tags encountered that aren't specified in the set will be treated as if they were part of the normal markdown text.
    public init(processing data: Data, customElementNames: Set<String> = []) throws(ParseError) {
        guard let text = String(data: data, encoding: .utf8) else {
            throw ParseError(kind: .nonUTF8Input, sourceLoc: .zero)
        }
        try self.init(processing: text, customElementNames: customElementNames)
    }
    
    /// Creates a new Markdown document by processing the contents of a file.
    ///
    /// Note that thie doesn't perform any Markdown parsing on its own; rather, it splits up a markdown file into a sequence of blocks,
    /// each of which is either markdown content or a custom HTML element.
    ///
    /// - parameter url: The URL of the markdown file to process.
    /// - parameter customElementNames: A `Set` of HTML tag names which should be processed into custom elements.
    ///     Any HTML tags encountered that aren't specified in the set will be treated as if they were part of the normal markdown text.
    public init(processingContentsOf url: URL, customElementNames: Set<String> = []) throws {
        try self.init(
            processing: Data(contentsOf: url),
            customElementNames: customElementNames
        )
    }
}
