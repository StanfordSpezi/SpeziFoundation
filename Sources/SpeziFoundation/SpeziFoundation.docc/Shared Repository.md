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

Working with a Shared Repository involves three steps:

1. **Define a `RepositoryAnchor`** — a plain struct conforming to ``RepositoryAnchor`` that scopes the repository
   and prevents mixing keys from unrelated domains.
2. **Define `KnowledgeSource` types** — each type acts as a typed key. The associated `Value` type determines
   what is stored. Conform to ``DefaultProvidingKnowledgeSource`` to supply a fallback value when nothing has
   been stored yet.
3. **Create and use a `ValueRepository`** — instantiate ``ValueRepository`` parameterised on your anchor, then
   read and write values through the typed subscript.

```swift
// 1. Define an anchor to scope the repository
struct MyAnchor: RepositoryAnchor {}

// 2a. A knowledge source whose value must be explicitly set
struct Username: KnowledgeSource {
    typealias Anchor = MyAnchor
    typealias Value = String
}

// 2b. A knowledge source that provides a default value
struct RequestCount: DefaultProvidingKnowledgeSource {
    typealias Anchor = MyAnchor
    typealias Value = Int

    static let defaultValue: Int = 0
}

// 3. Create a repository, write and read values
var repository = ValueRepository<MyAnchor>()

// Write a value
repository[Username.self] = "Jane"

// Read a plain KnowledgeSource — returns an Optional
let name: String? = repository[Username.self]   // "Jane"

// Read a DefaultProvidingKnowledgeSource — never returns nil
let count: Int = repository[RequestCount.self]  // 0  (default, nothing stored yet)

repository[RequestCount.self] = 42
let updatedCount: Int = repository[RequestCount.self]  // 42
```

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
