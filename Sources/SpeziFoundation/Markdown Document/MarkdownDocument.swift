//
// This source file is part of the Stanford Spezi open-source project
//
// SPDX-FileCopyrightText: 2025 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import Foundation


/// A Markdown document.
///
/// The ``MarkdownDocument`` struct is a lightweight data type representing a (potentially pre-processed) Markdown document,
/// consisting of optional metadata, and contents which are represented as a series of ``Block``s.
///
/// ### Metadata
///
/// When using any of the `processing:` initializers to create a ``MarkdownDocument`` (e.g.: ``init(processing:customElementNames:)-(String,_)``),
/// any frontmatter-style metadata entries at the very beginning of the input will be parsed into a ``Metadata-swift.struct`` object.
///
/// The frontmatter-style metadata takes the following format:
/// ```
/// ---
/// key1: value1
/// key2: value2
/// ---
/// ```
/// I.e., the metadata is a simple String-based key-value mapping, with one entry per line, that is enclosed within two `---` lines.
///
/// - Tip: If you just want to extract the metadata from a Markdown file and don't care about the rest of the document, you can use ``Metadata-swift.struct/init(parsing:)``.
///
/// ### Content Blocks
///
/// The ``blocks`` property stores the Markdown document's content, split up into a series of ``Block``s.
/// A block is either a section of Markdown-formatted text (``Block/markdown(id:rawContents:)``, or an extracted ``CustomElement`` (``Block/customElement(_:)``).
///
/// > Important: The ``MarkdownDocument`` does not perform any Markdown _parsing_;
///     it only performs _processing_ of the Markdown input, in the sense that it splits up the input text into a series of sections of Markdown text, and parses any custom tags that may be contained in the Markdown.
///
/// Additionally, the
/// For example, creating a ``MarkdownDocument`` from the following Markdown input (which ostensibly consists of two "parts": a markdown part with two sections, and a custom element part with a single signature field):
/// ```markdown
/// # Study Consent Form
/// Welcome to our study. As part of your participation, you will need to fill out and sign this consent form.
///
/// ## Your rights
/// You have the right to revoke this consent at any time; if you wish to do so, contact us at studies@acme.org
///
/// <signature id=sig />
/// ```
/// would result in a ``MarkdownDocument`` consisting of a total of three blocks: two markdown blocks (one per section) and one custom element block for the signature:
/// ```swift
/// MarkdownDocument(
///     metadata: [:],
///     blocks: [
///         .markdown(
///             id: "study-consent-form",
///             rawContents: """
///                 # Study Consent Form
///                 Welcome to our study. As part of your participation, you will need to fill out and sign this consent form.
///                 """
///         ),
///         .markdown(
///             id: "your-rights",
///             rawContents: """
///                 ## Your rights
///                 You have the right to revoke this consent at any time; if you wish to do so, contact us at studies@acme.org
///                 """
///         ),
///         .customElement(
///             MarkdownDocument.CustomElement(
///                 name: "signature",
///                 attributes: [.init(name: "id", value: "sig")],
///                 raw: "<signature id=sig />"
///             )
///         )
///    ]
/// )
/// ```
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
