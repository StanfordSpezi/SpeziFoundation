# Compression

<!--
#
# This source file is part of the Stanford Spezi open-source project
#
# SPDX-FileCopyrightText: 2026 Stanford University and the project authors (see CONTRIBUTORS.md)
#
# SPDX-License-Identifier: MIT
#
-->

Compress and decompress data using the Zstandard and zlib algorithms.

## Overview

SpeziFoundation bundles two compression algorithms behind a single, protocol-based API:

- ``Zstd`` wraps [Zstandard](https://github.com/facebook/zstd). It typically achieves better compression ratios *and* higher throughput than zlib,
  making it the recommended default for data that is only read back by your own app or backend.
- ``Zlib`` wraps [zlib](https://zlib.net/), i.e., the classic "deflate" algorithm. It is universally available,
  which makes it the right choice when interoperating with third-party systems or file formats that expect zlib streams.

Both conform to ``CompressionAlgorithm``, which defines the static ``CompressionAlgorithm/compress(_:options:)`` and ``CompressionAlgorithm/decompress(_:)`` functions.
In practice, you will usually go through the ``Swift/Collection/compressed(using:options:)`` and ``Swift/Collection/decompressed(using:)`` extensions instead,
which are available on every `Collection<UInt8>`, such as `Data` or `[UInt8]`:

```swift
let payload = try JSONEncoder().encode(samples)

let compressed = try payload.compressed(using: Zstd.self)
let restored = try compressed.decompressed(using: Zstd.self)
assert(restored == payload)
```

Since the algorithm is a type parameter rather than a runtime value, the compiler can inline the call and knows the exact error type that can be thrown (see below).
The trade-off is that the compressed data doesn't carry information about which algorithm produced it; decompress with the same algorithm you used for compression.

### Tuning the Compression Level

Every algorithm defines its own `CompressionOptions` type, whose `level` trades speed for output size.
Pass it to `compressed(using:options:)`; if you omit it, the algorithm's default level is used:

```swift
// Favor speed, e.g. for data that is compressed on-device before every upload.
let fast = try payload.compressed(using: Zstd.self, options: .init(level: .minRegular))

// Favor size, e.g. for archival exports that are written once and rarely read.
let small = try payload.compressed(using: Zstd.self, options: .init(level: .maxRegular))

// zlib uses the classic 0...9 scale, with `.none`, `.bestSpeed`, `.default`, and `.bestCompression` predefined.
let interoperable = try payload.compressed(using: Zlib.self, options: .init(level: .bestCompression))
```

Zstd levels range from ``Zstd/CompressionOptions/Level/minRegular`` (fastest) via ``Zstd/CompressionOptions/Level/default`` to ``Zstd/CompressionOptions/Level/maxRegular`` (smallest output);
zlib levels from ``Zlib/CompressionOptions/CompressionLevel/bestSpeed`` to ``Zlib/CompressionOptions/CompressionLevel/bestCompression``.
Both level types are `RawRepresentable`, so you can also pass the library's raw values directly.
Note that ``Zlib/CompressionOptions/CompressionLevel/init(rawValue:)`` validates its input (`0...9`, or the zlib default), whereas ``Zstd/CompressionOptions/Level/init(rawValue:)`` does not,
leaving it to the caller to only pass levels supported by the library.

### Error Handling

The compression APIs use typed throws: `compressed(using:)` throws the algorithm's `CompressionError`, and `decompressed(using:)` throws its `DecompressionError`.
For both built-in algorithms these are the same enum, with three cases:

- `invalidInput`: the input could not be processed. For compression, this happens if the input collection doesn't provide contiguous storage
  (`Data`, `Array`, and `ArraySlice` all do). For Zstd decompression, it also indicates that the input is not a Zstd frame,
  or that the frame doesn't declare its decompressed size. Frames produced by ``Zstd`` always do, but frames written by streaming compressors might not,
  in which case they cannot be decompressed using this API.
- `notEnoughMemory`: the underlying library failed to allocate memory.
- `other`: any other error reported by the underlying library, carrying the raw error code (`ZSTD_ErrorCode` for Zstd, the `Int32` status for zlib).
  Corrupt zlib input, for example, surfaces as `.other(Z_DATA_ERROR)`.

Because the error type is known at compile time, you can match on the cases directly, without casting:

```swift
do {
    let restored = try compressed.decompressed(using: Zstd.self)
    // ...
} catch Zstd.CompressionError.invalidInput {
    // `compressed` is not Zstd data, or the frame doesn't declare its decompressed size.
} catch Zstd.CompressionError.notEnoughMemory {
    // ...
} catch {
    // `error` is statically known to be a `Zstd.CompressionError`; the only remaining case is `.other(ZSTD_ErrorCode)`.
}
```

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
