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
/// - ``init(processing:)-(String)``
/// - ``init(processing:)-(Data)``
/// - ``init(processingContentsOf:)``
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
    
    public init(processing text: String) throws(ParseError) {
        let parser = MarkdownDocumentParser(input: text)
        self = try parser.parse()
    }
    
    public init(processing data: Data) throws(ParseError) {
        guard let text = String(data: data, encoding: .utf8) else {
            throw ParseError(kind: .nonUTF8Input, sourceLoc: .zero)
        }
        try self.init(processing: text)
    }
    
    public init(processingContentsOf url: URL) throws {
        try self.init(processing: Data(contentsOf: url))
    }
}
