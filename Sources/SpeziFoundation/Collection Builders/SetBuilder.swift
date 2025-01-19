//
// This source file is part of the Stanford Spezi open-source project
//
// SPDX-FileCopyrightText: 2024 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//


/// Result builder for constructing `Set`s.
@resultBuilder
public enum SetBuilder<Element: Hashable> {}


extension Set {
    /// Constructs a new `Set` using a result builder.
    public init(@SetBuilder<Element> build: () -> Set<Element>) {
        self = build()
    }
}


extension SetBuilder {
    /// :nodoc:
    public static func buildExpression(_ expression: Element) -> Set<Element> {
        Set(CollectionOfOne(expression))
    }
    
    /// :nodoc:
    public static func buildExpression(_ expression: some Sequence<Element>) -> Set<Element> {
        Set(expression)
    }
    
    /// :nodoc:
    public static func buildOptional(_ expression: Set<Element>?) -> Set<Element> { // swiftlint:disable:this discouraged_optional_collection
        expression ?? Set()
    }
    
    /// :nodoc:
    public static func buildEither(first expression: some Sequence<Element>) -> Set<Element> {
        Set(expression)
    }
    
    /// :nodoc:
    public static func buildEither(second expression: some Sequence<Element>) -> Set<Element> {
        Set(expression)
    }
    
    /// :nodoc:
    public static func buildPartialBlock(first: some Sequence<Element>) -> Set<Element> {
        Set(first)
    }
    
    /// :nodoc:
    public static func buildPartialBlock(accumulated: some Sequence<Element>, next: some Sequence<Element>) -> Set<Element> {
       Set(accumulated).union(next)
    }
    
    /// :nodoc:
    public static func buildBlock() -> Set<Element> {
        Set()
    }
    
    /// :nodoc:
    public static func buildArray(_ components: [some Sequence<Element>]) -> Set<Element> {
       components.reduce(into: Set()) { $0.formUnion($1) }
    }
    
    /// :nodoc:
    public static func buildFinalResult(_ component: Set<Element>) -> Set<Element> {
        component
    }
}
