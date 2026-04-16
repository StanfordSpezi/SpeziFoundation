//
// This source file is part of the Stanford Spezi open-source project
//
// SPDX-FileCopyrightText: 2026 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

public import struct Foundation.URL


/// Creates a `URL` from a string literal.
///
/// The macro validates that the input can be parsed into a `URL`, and emits a compile-time error if not.
///
/// ## Example:
/// ```swift
/// let url = #url("https://stanford.edu")
/// ```
///
/// - parameter literal: The URL literal
@freestanding(expression)
public macro url(
    _ literal: StaticString
) -> URL = #externalMacro(module: "SpeziFoundationMacros", type: "URLMacro")
