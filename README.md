<!--
                  
This source file is part of the Stanford Spezi open-source project

SPDX-FileCopyrightText: 2022 Stanford University and the project authors (see CONTRIBUTORS.md)

SPDX-License-Identifier: MIT
             
-->

# SpeziFoundation

[![CI](https://github.com/StanfordSpezi/SpeziFoundation/actions/workflows/ci.yml/badge.svg)](https://github.com/StanfordSpezi/SpeziFoundation/actions/workflows/ci.yml)
[![codecov](https://codecov.io/gh/StanfordSpezi/SpeziFoundation/graph/badge.svg?token=9S5PQRVKF8)](https://codecov.io/gh/StanfordSpezi/SpeziFoundation)
[![DOI](https://zenodo.org/badge/DOI/10.5281/zenodo.10077558.svg)](https://doi.org/10.5281/zenodo.10077558)
[![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2FStanfordSpezi%2FSpeziFoundation%2Fbadge%3Ftype%3Dswift-versions)](https://swiftpackageindex.com/StanfordSpezi/SpeziFoundation)
[![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2FStanfordSpezi%2FSpeziFoundation%2Fbadge%3Ftype%3Dplatforms)](https://swiftpackageindex.com/StanfordSpezi/SpeziFoundation)

Spezi Foundation provides a base layer of functionality useful in many applications, including fundamental types, algorithms, extensions, and data structures.


## Components

The SpeziFoundation package consists of 2 targets:
- [SpeziFoundation](https://swiftpackageindex.com/StanfordSpezi/SpeziFoundation/documentation/spezifoundation):
    - Extensions related to concurrency, collection, etc;
    - Data structures;
    - Markdown processing
    - See [the docs](https://swiftpackageindex.com/StanfordSpezi/SpeziFoundation/documentation/spezifoundation) for an exhaustive list. 
- [SpeziLocalization](https://swiftpackageindex.com/StanfordSpezi/SpeziFoundation/documentation/spezilocalization):
    - Localization-related utilities, for working with both string and file-level localization 


## Usage Examples

### `@LocalPreference` — type-safe UserDefaults

```swift
// 1. Define a key
extension LocalPreferenceKeys {
    static let username = LocalPreferenceKey<String>("username", default: "Guest")
}

// 2. Use it in a SwiftUI View
struct SettingsView: View {
    @LocalPreference(.username) var username

    var body: some View {
        TextField("Username", text: $username)
    }
}
```

### `AsyncSemaphore` — limit concurrent async work

```swift
let semaphore = AsyncSemaphore(value: 3) // at most 3 simultaneous requests

func fetch(_ url: URL) async throws -> Data {
    try await semaphore.waitCheckingCancellation()
    defer { semaphore.signal() }
    let (data, _) = try await URLSession.shared.data(from: url)
    return data
}
```

### `withManagedTaskQueue` — bounded batch processing

```swift
await withManagedTaskQueue(limit: 4) { queue in
    for item in workItems {
        queue.addTask { await process(item) }
    }
}
```

### `SharedRepository` — typed key-value store

```swift
struct AppAnchor: RepositoryAnchor {}

struct UserID: DefaultProvidingKnowledgeSource {
    typealias Anchor = AppAnchor
    typealias Value = String
    static let defaultValue = "anonymous"
}

var repo = ValueRepository<AppAnchor>()
repo[UserID.self] = "user-42"
let id: String = repo[UserID.self]  // "user-42"
```

### `Version` — semantic versioning

```swift
let current: Version = "2.1.0"
let minimum: Version = "2.0.0"

if current >= minimum {
    print("Requirements met")
}
```

### Compression — Zstd / Zlib

```swift
let data = Data("Hello, Spezi!".utf8)
let compressed   = try data.compressed(using: Zstd.self)
let decompressed = try compressed.decompressed(using: Zstd.self)
```


## Installation

The project can be added to your Xcode project or Swift Package using the [Swift Package Manager](https://github.com/apple/swift-package-manager).

**Xcode:** For an Xcode project, follow the instructions on [adding package dependencies to your app](https://developer.apple.com/documentation/xcode/adding-package-dependencies-to-your-app).

**Swift Package:** You can follow the [Swift Package Manager documentation about defining dependencies](https://docs.swift.org/swiftpm/documentation/packagemanagerdocs/addingdependencies) to add this project as a dependency to your Swift Package.


## Contributing

Contributions to this project are welcome. Please make sure to read the [contribution guidelines](https://github.com/StanfordSpezi/.github/blob/main/CONTRIBUTING.md) and the [contributor covenant code of conduct](https://github.com/StanfordSpezi/.github/blob/main/CODE_OF_CONDUCT.md) first.

## Testing on Linux

You can test SpeziFoundation on Linux using Docker. To do this, run the following command:

```bash
docker build -t spezi-foundation .
```

This will build the container and run the tests.


## License

This project is licensed under the MIT License. See [Licenses](https://github.com/StanfordSpezi/Spezi/tree/main/LICENSES) for more information.

![Spezi Footer](https://raw.githubusercontent.com/StanfordSpezi/.github/main/assets/Footer.png#gh-light-mode-only)
![Spezi Footer](https://raw.githubusercontent.com/StanfordSpezi/.github/main/assets/Footer~dark.png#gh-dark-mode-only)
