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
    
    public init(processing text: String, customElementNames: Set<String> = []) throws(ParseError) {
        let parser = Parser(input: text, customElementNames: customElementNames)
        self = try parser.parse()
    }
    
    public init(processing data: Data, customElementNames: Set<String> = []) throws(ParseError) {
        guard let text = String(data: data, encoding: .utf8) else {
            throw ParseError(kind: .nonUTF8Input, sourceLoc: .zero)
        }
        try self.init(processing: text, customElementNames: customElementNames)
    }
    
    public init(processingContentsOf url: URL, customElementNames: Set<String> = []) throws {
        try self.init(
            processing: Data(contentsOf: url),
            customElementNames: customElementNames
        )
    }
}
