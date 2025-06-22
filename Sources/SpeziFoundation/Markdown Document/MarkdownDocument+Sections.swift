//
// This source file is part of the Stanford Spezi open-source project
//
// SPDX-FileCopyrightText: 2025 Stanford University
//
// SPDX-License-Identifier: MIT
//

import Foundation


extension MarkdownDocument {
    public enum Block: Hashable, Sendable {
        case markdown(String)
        case customElement(ParsedCustomElement)
    }
    
    public struct ParsedCustomElement: Hashable, Sendable {
        public indirect enum Content: Hashable, Sendable {
            case text(String)
            case element(ParsedCustomElement)
        }
        
        public struct ParsedAttribute: Hashable, Sendable {
            public let name: String
            public let value: String
        }
        
        public internal(set) var name: String
        public internal(set) var attributes: [ParsedAttribute] = []
        public internal(set) var content: [Content] = []
        
        public subscript(attribute name: String) -> String? {
            attributes.first { $0.name == name }?.value
        }
    }
}
