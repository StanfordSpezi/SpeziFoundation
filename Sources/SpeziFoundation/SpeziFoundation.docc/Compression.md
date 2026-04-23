<!--
This source file is part of the Stanford Spezi open-source project

SPDX-FileCopyrightText: 2026 Stanford University and the project authors (see CONTRIBUTORS.md)

SPDX-License-Identifier: MIT
-->

# Compression

Compress and decompress data using industry-standard algorithms.

## Overview

SpeziFoundation provides a lightweight, protocol-driven compression API that supports two widely-used algorithms: **Zstd** and **Zlib**.

- ``Zstd`` wraps the [Zstandard](https://github.com/facebook/zstd) library developed by Meta. It offers excellent compression ratios and high throughput, making it a strong general-purpose choice. Compression level can be tuned from ``Zstd/CompressionOptions/Level/minRegular`` (fastest) to ``Zstd/CompressionOptions/Level/maxRegular`` (smallest output).
- ``Zlib`` wraps the classic [zlib](https://zlib.net/) deflate algorithm. It is universally supported and interoperable with many existing systems and file formats. Its level can range from ``Zlib/CompressionOptions/CompressionLevel/bestSpeed`` to ``Zlib/CompressionOptions/CompressionLevel/bestCompression``.

Both algorithms conform to ``CompressionAlgorithm`` and are accessible through convenience methods on any `Collection<UInt8>`, including `Data`.

### Compressing Data

Call ``Swift/Collection/compressed(using:options:)`` on any `Collection<UInt8>`, passing the algorithm type. The call uses typed throws, so the compiler knows exactly which error type can be thrown.

```swift
import Foundation
import SpeziFoundation

let payload = Data("Hello, Spezi!".utf8)

// Compress using Zstd with default options
let compressed = try payload.compressed(using: Zstd.self)

// Compress using Zstd with a specific compression level
let fastCompressed = try payload.compressed(
    using: Zstd.self,
    options: Zstd.CompressionOptions(level: .minRegular)
)

// Compress using Zlib
let zlibCompressed = try payload.compressed(using: Zlib.self)
```

### Decompressing Data

Call ``Swift/Collection/decompressed(using:)`` on compressed bytes, using the same algorithm that was used to compress them.

```swift
let decompressed = try compressed.decompressed(using: Zstd.self)
let original = String(data: decompressed, encoding: .utf8) // "Hello, Spezi!"
```

### Error Handling

Both ``Zstd`` and ``Zlib`` use typed throws, so you can switch exhaustively on the error cases.

```swift
do {
    let compressed = try payload.compressed(using: Zstd.self)
    let decompressed = try compressed.decompressed(using: Zstd.self)
    print("Round-trip succeeded: \(decompressed.count) bytes")
} catch Zstd.CompressionError.invalidInput {
    print("Input data is not valid Zstd data.")
} catch Zstd.CompressionError.notEnoughMemory {
    print("Insufficient memory to complete the operation.")
} catch {
    print("Unexpected error: \(error)")
}
```

For Zlib the pattern is identical — substitute ``Zlib`` and `Zlib.CompressionError`.

## Topics

### Compression Protocol

- ``CompressionAlgorithm``
- ``CompressionOptionsProtocol``

### Algorithms

- ``Zstd``
- ``Zlib``

### Collection Extensions

- ``Swift/Collection/compressed(using:options:)``
- ``Swift/Collection/decompressed(using:)``
