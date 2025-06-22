//
// This source file is part of the Stanford Spezi open-source project
//
// SPDX-FileCopyrightText: 2025 Stanford University
//
// SPDX-License-Identifier: MIT
//

import Foundation


extension MarkdownDocument {
    /// A unit of content within a ``MarkdownDocument``.
    public enum Block: Hashable, Sendable {
        /// A block of Markdown text
        case markdown(id: String?, rawContents: String)
        /// A parsed custom element.
        case customElement(CustomElement)
        
        /// The block's stable identifier, if available.
        public var id: String? {
            switch self {
            case .markdown(let id, _):
                id
            case .customElement(let element):
                element[attribute: "id"]
            }
        }
    }
    
    /// A custom element that was parsed from a Markdown string.
    public struct CustomElement: Hashable, Sendable {
        /// The element's content
        public indirect enum Content: Hashable, Sendable {
            /// A piece of plain-text content
            case text(String)
            /// Another element.
            case element(CustomElement)
        }
        
        /// An attribute within a parsed element.
        ///
        /// Attributes are modeled after HTML attributes, and are simple key-value pairs of the form `name=value`.
        public struct ParsedAttribute: Hashable, Sendable {
            /// The attribute's name
            public let name: String
            /// The attribute's value
            public let value: String
        }
        
        /// The element name.
        public internal(set) var name: String
        /// The element's attributes.
        public internal(set) var attributes: [ParsedAttribute] = []
        /// The element's content.
        public internal(set) var content: [Content] = []
        /// The unprocessed raw text from which this element was parsed.
        public internal(set) var raw: String
        
        /// Reads the value of the first attribute with the specified name, if available.
        public subscript(attribute name: String) -> String? {
            attributes.first { $0.name == name }?.value
        }
    }
}
