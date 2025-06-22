//
// This source file is part of the Stanford Spezi open-source project
//
// SPDX-FileCopyrightText: 2025 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

@testable import SpeziFoundation
import Testing


@Suite
struct MarkdownDocumentTests {
    @Test
    func parse() throws {
        let input = """
            # Hello World
            
            How are you doing?
            """
        let doc = try MarkdownDocument(processing: input)
        #expect(doc == MarkdownDocument(metadata: .init(), blocks: [
            .markdown("# Hello World\n\nHow are you doing?")
        ]))
    }
    
    @Test
    func metadata() throws {
        let input = """
            ---
            title: Document Title
            version: 1.0.0
            ---
            """
        let doc = try MarkdownDocument(processing: input)
        #expect(doc == MarkdownDocument(
            metadata: [
                "title": "Document Title",
                "version": "1.0.0"
            ],
            blocks: []
        ))
    }
    
    @Test
    func customElements() throws { // swiftlint:disable:this function_body_length
        let input = """
            # Hello World
            
            Welcome to our Study
            
            <toggle id=t1 initial-value=false expected-value=true>
                I'm fine with some of my health data being used for scientific research.
            </toggle>
            
            Selection block:
            
            <select id=s1 initial-value=o1 expected-value="*">
                Please select a value:
                <option id=o0>T0</option>
                <option id=o1>T1</option>
                Or maybe this one?
                <option id=o2>T2</option>
            </select>
            
            Please sign the form below:
            <signature id=s1 />
            """
        let doc = try MarkdownDocument(processing: input, customElementNames: ["toggle", "select", "signature", "option"])
        #expect(doc == MarkdownDocument(
            metadata: .init(),
            blocks: [
                .markdown("# Hello World\n\nWelcome to our Study"),
                .customElement(.init(
                    name: "toggle",
                    attributes: [
                        .init(name: "id", value: "t1"),
                        .init(name: "initial-value", value: "false"),
                        .init(name: "expected-value", value: "true")
                    ],
                    content: [
                        .text("I'm fine with some of my health data being used for scientific research.")
                    ],
                    raw: """
                        <toggle id=t1 initial-value=false expected-value=true>
                            I'm fine with some of my health data being used for scientific research.
                        </toggle>
                        """
                )),
                .markdown("Selection block:"),
                .customElement(.init(
                    name: "select",
                    attributes: [
                        .init(name: "id", value: "s1"),
                        .init(name: "initial-value", value: "o1"),
                        .init(name: "expected-value", value: "*")
                    ],
                    content: [
                        .text("Please select a value:"),
                        .element(.init(
                            name: "option",
                            attributes: [.init(name: "id", value: "o0")],
                            content: [.text("T0")],
                            raw: "<option id=o0>T0</option>"
                        )),
                        .element(.init(
                            name: "option",
                            attributes: [.init(name: "id", value: "o1")],
                            content: [.text("T1")],
                            raw: "<option id=o1>T1</option>"
                        )),
                        .text("Or maybe this one?"),
                        .element(.init(
                            name: "option",
                            attributes: [.init(name: "id", value: "o2")],
                            content: [.text("T2")],
                            raw: "<option id=o2>T2</option>"
                        ))
                    ],
                    raw: """
                        <select id=s1 initial-value=o1 expected-value="*">
                            Please select a value:
                            <option id=o0>T0</option>
                            <option id=o1>T1</option>
                            Or maybe this one?
                            <option id=o2>T2</option>
                        </select>
                        """
                )),
                .markdown("Please sign the form below:"),
                .customElement(.init(
                    name: "signature",
                    attributes: [.init(name: "id", value: "s1")],
                    content: [],
                    raw: "<signature id=s1 />"
                ))
            ]
        ))
    }
}
