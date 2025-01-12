//
// This source file is part of the Stanford Spezi open-source project
//
// SPDX-FileCopyrightText: 2024 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//


/// A result builder that constructs an instance of a `RangeReplaceableCollection`.
@resultBuilder
public enum RangeReplaceableCollectionBuilder<C: RangeReplaceableCollection> {
    /// The `Element` of the `RangeReplaceableCollection` that will be built up.
    public typealias Element = C.Element
}


extension RangeReplaceableCollectionBuilder {
    /// :nodoc:
    public static func buildExpression(_ expression: Element) -> C {
        C(CollectionOfOne(expression))
    }
    
    /// :nodoc:
    public static func buildExpression(_ expression: some Sequence<Element>) -> C {
        C(expression)
    }
    
    /// :nodoc:
    public static func buildOptional(_ expression: C?) -> C {
        expression ?? C()
    }
    
    /// :nodoc:
    public static func buildEither(first expression: some Sequence<Element>) -> C {
        C(expression)
    }
    
    /// :nodoc:
    public static func buildEither(second expression: some Sequence<Element>) -> C {
        C(expression)
    }
    
    /// :nodoc:
    public static func buildPartialBlock(first: some Sequence<Element>) -> C {
        C(first)
    }
    
    /// :nodoc:
    public static func buildPartialBlock(accumulated: some Sequence<Element>, next: some Sequence<Element>) -> C {
        C(accumulated) + C(next)
    }
    
    /// :nodoc:
    public static func buildBlock() -> C {
        C()
    }
    
    /// :nodoc:
    public static func buildArray(_ components: [some Sequence<Element>]) -> C {
        components.reduce(into: C()) { $0.append(contentsOf: $1) }
    }
    
    /// :nodoc:
    public static func buildFinalResult(_ component: C) -> C {
        component
    }
}
