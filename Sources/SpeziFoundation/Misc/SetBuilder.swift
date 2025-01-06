//
//  File.swift
//  SpeziFoundation
//
//  Created by Lukas Kollmer on 2024-12-20.
//


@resultBuilder
public enum SetBuilder<Element: Hashable> {
    public static func make(@SetBuilder build: () -> Set<Element>) -> Set<Element> {
        build()
    }
}

public extension SetBuilder {
    static func buildExpression(_ expression: Element) -> Set<Element> {
        [expression]
    }
    
    static func buildExpression(_ expression: some Sequence<Element>) -> Set<Element> {
        Set(expression)
    }
    
    static func buildOptional(_ expression: Set<Element>?) -> Set<Element> {
        expression ?? Set()
    }
    
    static func buildOptional(_ expression: (some Sequence<Element>)?) -> Set<Element> {
        expression.map(Set.init) ?? Set()
    }
    
    static func buildEither(first expression: some Sequence<Element>) -> Set<Element> {
        Set(expression)
    }
    
    static func buildEither(second expression: some Sequence<Element>) -> Set<Element> {
        Set(expression)
    }
    
    static func buildPartialBlock(first: some Sequence<Element>) -> Set<Element> {
        Set(first)
    }
    
    static func buildPartialBlock(accumulated: some Sequence<Element>, next: some Sequence<Element>) -> Set<Element> {
       Set(accumulated).union(next)
    }
    
    static func buildBlock(_ components: Element...) -> Set<Element> {
       Set(components)
    }
    
    static func buildArray(_ components: [some Sequence<Element>]) -> Set<Element> {
       components.reduce(into: Set()) { $0.formUnion($1) }
    }
}

