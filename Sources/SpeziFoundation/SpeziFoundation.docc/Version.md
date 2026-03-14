<!--
This source file is part of the Stanford Spezi open-source project

SPDX-FileCopyrightText: 2026 Stanford University and the project authors (see CONTRIBUTORS.md)

SPDX-License-Identifier: MIT
-->

# Version

Represent and compare software versions using the Semantic Versioning 2.0.0 specification.

## Overview

``Version`` is a value type that models a [SemVer 2.0.0](https://semver.org/) version string. It stores the three required numeric components — ``Version/major``, ``Version/minor``, and ``Version/patch`` — as well as optional pre-release identifiers and build metadata. Versions are fully `Comparable`, `Hashable`, `Codable`, and `Sendable`.

### Creating a Version

You can create a `Version` from a string literal, from its numeric components directly, or by parsing an arbitrary `String` at runtime.

```swift
// From a string literal (traps at runtime if the literal is invalid)
let release: Version = "2.1.0"

// From numeric components
let v1 = Version(1, 0, 0)

// Failable parse of a runtime string
if let v2 = Version.init("3.0.0-beta.1") {
    print(v2) // "3.0.0-beta.1"
}
```

> Note: When you write `Version("1.2.3")` in source code the compiler selects ``Version/init(stringLiteral:)``, which traps on an invalid value. To call the failable ``Version/init(_:)-swift.init`` with a string literal, use an explicit `init` call: `Version.init("1.2.3")`.

### Accessing Components

```swift
let version: Version = "1.4.2"

print(version.major) // 1
print(version.minor) // 4
print(version.patch) // 2
```

### Comparing Versions

`Version` conforms to `Comparable`, so you can use the full suite of comparison operators. Precedence follows the SemVer specification: `major` is compared first, then `minor`, then `patch`. A pre-release version has lower precedence than the corresponding normal release.

```swift
let stable: Version = "1.0.0"
let patch: Version  = "1.0.1"
let major: Version  = "2.0.0"

print(stable < patch)  // true
print(patch  < major)  // true
print(major >= stable) // true

// Pre-release sorts below the normal release
let alpha: Version = "1.0.0-alpha"
print(alpha < stable)  // true
```

### Pre-release Identifiers and Build Metadata

Pre-release information is stored as an array of dot-separated identifier strings. Build metadata is stored the same way but, per the SemVer spec, is ignored during precedence comparisons.

```swift
let beta = Version(1, 0, 0, prereleaseIdentifiers: ["beta", "1"])
print(beta.prereleaseIdentifiers) // ["beta", "1"]
print(beta.isPrereleaseVersion)   // true
print(beta.description)           // "1.0.0-beta.1"

let withMeta = Version(1, 0, 0, buildMetadata: ["20260314", "exp"])
print(withMeta.buildMetadata) // ["20260314", "exp"]
print(withMeta.description)   // "1.0.0+20260314.exp"
```

## Topics

### Creating a Version

- ``Version/init(_:_:_:)``
- ``Version/init(_:_:_:prereleaseIdentifiers:buildMetadata:)``
- ``Version/init(_:)-swift.init``
- ``Version/init(stringLiteral:)``

### Version Components

- ``Version/major``
- ``Version/minor``
- ``Version/patch``
- ``Version/prereleaseIdentifiers``
- ``Version/buildMetadata``

### Inspecting a Version

- ``Version/isPrereleaseVersion``
- ``Version/description``

### Comparing Versions

- ``Version/<(_:_:)``
- ``Version/==(_:_:)``

### Encoding and Decoding

- ``Version/init(from:)``
- ``Version/encode(to:)``
