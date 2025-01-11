//
// This source file is part of the Stanford Spezi open-source project
//
// SPDX-FileCopyrightText: 2024 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//


/// An `ArrayBuilder<T>` is a result builder that constructs an `Array<T>`.
public typealias ArrayBuilder<T> = RangeReplaceableCollectionBuilder<[T]>

extension Array {
    /// Constructs a new array, using a result builder.
    public init(@ArrayBuilder<Element> build: () -> Self) {
        self = build()
    }
}
