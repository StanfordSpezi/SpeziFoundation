//
// This source file is part of the Stanford Spezi open-source project
//
// SPDX-FileCopyrightText: 2025 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//


#if canImport(os)
@_documentation(visibility: internal) @_exported import OSLog

/// A unified type alias for the system `Logger` on supported Apple platforms.
///
/// > Important: On non-Apple platforms (such as Linux or Windows) where `os` is unavailable, this type automatically aliases to `Logging.Logger` from [swift-log](https://github.com/apple/swift-log). To ensure source compatibility, an extension is provided for `Logging.Logger` that adds the `init(subsystem:category:)` initializer.
public typealias SpeziLogger = Logger
#else
@_documentation(visibility: internal) @_exported import Logging

/// A unified type alias for `Logging.Logger` on non-Apple platforms.
public typealias SpeziLogger = Logger

extension Logger {
    /// Creates a logger instance using the `os.Logger` initialization style.
    ///
    /// - Parameters:
    ///   - subsystem: Mapped to `label`.
    ///   - category: Stored in metadata key "category".
    public init(subsystem: String, category: String) {
        self.init(label: subsystem)
        self[metadataKey: "category"] = "\(category)"
    }
}
#endif
