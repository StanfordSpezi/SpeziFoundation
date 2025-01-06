//
//  File.swift
//  SpeziFoundation
//
//  Created by Lukas Kollmer on 2024-11-30.
//


public typealias ArrayBuilder<T> = RangeReplaceableCollectionBuilder<[T]>

public extension Array {
    init(@ArrayBuilder<Element> build: () -> Self) {
        self = build()
    }
}


// MARK: RangeReplaceableCollectionBuilder

@resultBuilder
public enum RangeReplaceableCollectionBuilder<C: RangeReplaceableCollection> {
    public typealias Element = C.Element
    public static func make(@RangeReplaceableCollectionBuilder build: () -> C) -> C {
        build()
    }
}

public extension RangeReplaceableCollectionBuilder {
    static func buildExpression(_ expression: Element) -> C {
        C(CollectionOfOne(expression))
    }
    
    static func buildExpression(_ expression: some Sequence<Element>) -> C {
        C(expression)
    }
    
    static func buildOptional(_ expression: C?) -> C {
        expression ?? C()
    }
    
    static func buildOptional(_ expression: (some Sequence<Element>)?) -> C {
        expression.map(C.init) ?? C()
    }
    
    static func buildEither(first expression: some Sequence<Element>) -> C {
        C(expression)
    }
    
    static func buildEither(second expression: some Sequence<Element>) -> C {
        C(expression)
    }
    
    static func buildPartialBlock(first: some Sequence<Element>) -> C {
        C(first)
    }
    
    static func buildPartialBlock(accumulated: some Sequence<Element>, next: some Sequence<Element>) -> C {
        C(accumulated) + C(next)
    }
    
    static func buildBlock() -> C {
        C()
    }
    
    static func buildBlock(_ components: Element...) -> C {
        C(components)
    }
    
    static func buildArray(_ components: [some Sequence<Element>]) -> C {
        components.reduce(into: C()) { $0.append(contentsOf: $1) }
    }
}
