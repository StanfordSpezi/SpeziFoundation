//
// This source file is part of the Stanford Spezi open-source project
//
// SPDX-FileCopyrightText: 2023 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//


/// A ``KnowledgeSource`` that allows to compose it's values from it's surrounding knowledge environment
/// but may deliver a optional value.
public protocol OptionalComputedKnowledgeSource<Anchor, Repository>: SomeComputedKnowledgeSource {
    associatedtype Repository

    /// Computes the value of the ``KnowledgeSource``.
    ///
    /// - Note: The implementation of this method must be deterministic.
    /// - Parameter repository: The repository to use for computation.
    /// - Returns: Returns the computed value or nil if nothing could be computed.
    @Sendable
    static func compute(from repository: Repository) -> Value?
}
