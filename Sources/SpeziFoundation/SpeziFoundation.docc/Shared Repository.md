# Shared Repository

<!--
This source file is part of the Stanford Spezi open-source project

SPDX-FileCopyrightText: 2023 Stanford University and the project authors (see CONTRIBUTORS.md)

SPDX-License-Identifier: MIT
-->

A common interface for a storage mechanism that allows multiple entities to access, provide and modify shared data.

## Overview

A Shared Repository is a software pattern that allows to easily integrate application functionality with
a data-driven control flow or applications that operate on the same data, but do not share the same processing
workflow or are split across multiple software systems.

This implementation is a modified version of the Shared Repository as described by
Buschmann et al. in _Pattern-Oriented Software Architecture: A Pattern Language for Distributed Computing_.

A ``SharedRepository`` acts as a typed collection. Stored data is defined and keyed by ``KnowledgeSource`` instances.
You can constrain the applicable ``KnowledgeSource``s by defining a ``RepositoryAnchor``

- Note: Refer to ``SendableSharedRepository`` for a `Sendable` version of a shared repository.

### Using a Shared Repository

A shared repository is a dictionary whose keys are *types*: every ``KnowledgeSource`` type acts as a key, and its `Value` associated type determines the type of the stored value.
This yields a heterogeneous, yet fully type-checked store: the compiler knows which type `repository[ParticipantId.self]` returns,
and a key defined by one module can be read by another one, without either of them having to agree on a shared enumeration of keys.

Setting up a shared repository involves three steps:

1. Define a ``RepositoryAnchor``. The anchor is an empty type that scopes a family of keys to a repository; the compiler rejects keys that are anchored elsewhere.
2. Define your ``KnowledgeSource`` types. `Value` defaults to the source type itself, so a type can act as its own key.
   Conform to ``DefaultProvidingKnowledgeSource`` if reads should fall back to a default value rather than returning `nil`.
3. Store values in a ``ValueRepository``, or a ``SendableValueRepository`` if the repository itself needs to be `Sendable` (in which case all stored values need to be `Sendable` as well).

```swift
// 1. The anchor.
struct StudyAnchor: RepositoryAnchor {}

// 2a. A key with an explicit value type. Reads return an Optional.
enum ParticipantId: KnowledgeSource {
    typealias Anchor = StudyAnchor
    typealias Value = String
}

// 2b. A type that is its own key; `Value` defaults to `Self`.
struct EnrollmentDate: KnowledgeSource {
    typealias Anchor = StudyAnchor
    let date: Date
}

// 2c. A key with a default value. Reads never return nil.
enum CompletedTaskCount: DefaultProvidingKnowledgeSource {
    typealias Anchor = StudyAnchor
    typealias Value = Int
    static let defaultValue = 0
}

// 3. The repository.
var repository = ValueRepository<StudyAnchor>()

repository[ParticipantId.self] = "P-042"
repository[EnrollmentDate.self] = EnrollmentDate(date: .now)

let id: String? = repository[ParticipantId.self]           // "P-042"
let count: Int = repository[CompletedTaskCount.self]       // 0, since nothing has been stored yet
repository[CompletedTaskCount.self] = count + 1

repository[ParticipantId.self] = nil                        // removes the entry
let isEnrolled = repository.contains(EnrollmentDate.self)   // true
```

A default that isn't part of the key's definition can be supplied at the call site via ``SharedRepository/subscript(_:default:)``, e.g. `repository[ParticipantId.self, default: "anonymous"]`.
``SharedRepository/collect(allOf:)`` returns all stored values that can be cast to a given type, which allows a module to process every value conforming to a protocol it defines,
without knowing the concrete keys under which they were stored.

### Computed Knowledge Sources

A ``ComputedKnowledgeSource`` derives its value from the repository's other contents instead of being stored explicitly.
Its `StoragePolicy` determines whether the computed value is cached in the repository (``SomeComputedKnowledgeSource/Store``, the default) or recomputed on every access (``SomeComputedKnowledgeSource/AlwaysCompute``).
Use an ``OptionalComputedKnowledgeSource`` if the computation may not produce a value:

```swift
enum DisplayName: ComputedKnowledgeSource {
    typealias Anchor = StudyAnchor
    typealias Value = String
    typealias StoragePolicy = AlwaysCompute

    static func compute(from repository: ValueRepository<StudyAnchor>) -> String {
        repository[ParticipantId.self].map { "Participant \($0)" } ?? "Unknown Participant"
    }
}

let name = repository[DisplayName.self]
```

### Shared Repositories in the Spezi Ecosystem

The shared repository is one of the central building blocks of Spezi:

- `Spezi` stores the values that modules provide (via `@Provide`) and collect (via `@Collect`) in its `SpeziStorage`, a `ValueRepository<SpeziAnchor>`.
- `SpeziAccount` represents a user's account details as a `SendableValueRepository<AccountAnchor>`.
  Every `AccountKey` (user id, email address, date of birth, ...) is a `KnowledgeSource<AccountAnchor>`, and other packages can define additional keys without modifying `SpeziAccount`.
- `SpeziScheduler` stores the user info attached to tasks and outcomes in shared repositories, using dedicated anchors for each.

## Topics

### Shared Repository

- ``ValueRepository``
- ``SendableValueRepository``
- ``SharedRepository``
- ``SendableSharedRepository``

### Knowledge Sources

- ``KnowledgeSource``
- ``DefaultProvidingKnowledgeSource``
- ``ComputedKnowledgeSource``
- ``OptionalComputedKnowledgeSource``

### Implementing a Shared Repository

- ``RepositoryAnchor``
- ``RepositoryValue``
- ``AnyRepositoryValue``

### Computed Knowledge Sources

- ``SomeComputedKnowledgeSource``
- ``ComputedKnowledgeSourceStoragePolicy``
