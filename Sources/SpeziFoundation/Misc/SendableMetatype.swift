//
// This source file is part of the Stanford Spezi open-source project
//
// SPDX-FileCopyrightText: 2025 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//


#if compiler(<6.2)
/// Pre Swift 6.2 typealias for `SendableMetatype` that resolves as `Any` to avoid larger `#if` statements in the code base.
public typealias SendableMetatype = Any
#endif
