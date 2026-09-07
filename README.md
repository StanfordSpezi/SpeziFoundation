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

The SpeziFoundation package consists of 2 targets: [SpeziFoundation](https://swiftpackageindex.com/StanfordSpezi/SpeziFoundation/documentation/spezifoundation) and [SpeziLocalization](https://swiftpackageindex.com/StanfordSpezi/SpeziFoundation/documentation/spezilocalization).

### SpeziFoundation

The `SpeziFoundation` target provides general-purpose functionality that is shared by the other Spezi modules and available to apps built with Spezi:

| Area | What it provides | Documentation |
| --- | --- | --- |
| Shared Repository | A type-safe key-value store (`ValueRepository`, `SendableValueRepository`) whose keys are `KnowledgeSource` types, scoped to a `RepositoryAnchor`. Modules use it to exchange values without knowing about each other. | [Shared Repository](https://swiftpackageindex.com/StanfordSpezi/SpeziFoundation/documentation/spezifoundation/shared-repository) |
| Local Preferences | `@LocalPreference` and `LocalPreferencesStore`: a type-safe, namespaced alternative to `AppStorage` and `UserDefaults`, including support for migrations. | [Local Preferences](https://swiftpackageindex.com/StanfordSpezi/SpeziFoundation/documentation/spezifoundation/localpreferences) |
| Concurrency | `AsyncSemaphore`, `withManagedTaskQueue`, `ManagedAsynchronousAccess`, `RWLock`, cancelable child tasks, and `withTimeout`. | [Concurrency](https://swiftpackageindex.com/StanfordSpezi/SpeziFoundation/documentation/spezifoundation/concurrency) |
| Data Structures | `OrderedArray`, an always-sorted array with binary-search lookups, and `Version`, an implementation of Semantic Versioning 2.0.0. | [OrderedArray](https://swiftpackageindex.com/StanfordSpezi/SpeziFoundation/documentation/spezifoundation/orderedarray), [Version](https://swiftpackageindex.com/StanfordSpezi/SpeziFoundation/documentation/spezifoundation/version) |
| Collection Algorithms | Binary search, `Set`-producing `map` variants, sorting with heterogeneous `SortComparator`s, and safe indexing. | [Collection Algorithms](https://swiftpackageindex.com/StanfordSpezi/SpeziFoundation/documentation/spezifoundation/collectionalgorithms) |
| Compression | Zstandard and zlib compression behind a common `CompressionAlgorithm` protocol, with typed errors. | [Compression](https://swiftpackageindex.com/StanfordSpezi/SpeziFoundation/documentation/spezifoundation/compression) |
| Markdown | `MarkdownDocument`: front-matter metadata parsing and extraction of custom elements (e.g., signature fields) from Markdown input. | [MarkdownDocument](https://swiftpackageindex.com/StanfordSpezi/SpeziFoundation/documentation/spezifoundation/markdowndocument) |
| Calendar and Time Zone | `Calendar` helpers for component-based date ranges and distances, and DST transition lookups on `TimeZone`. | [Calendar](https://swiftpackageindex.com/StanfordSpezi/SpeziFoundation/documentation/spezifoundation/calendar) |
| Logging | A `Logger` type that maps to `os.Logger` on Apple platforms and to `swift-log` elsewhere, so the same code works on Linux. | [Logger](https://swiftpackageindex.com/StanfordSpezi/SpeziFoundation/documentation/spezifoundation/logger) |
| Other | Result builders for arrays and sets, `TopLevelEncoder`/`TopLevelDecoder` protocols, `DataDescriptor` for masked byte matching, Objective-C exception catching, and a testing SPI. | [SpeziFoundation](https://swiftpackageindex.com/StanfordSpezi/SpeziFoundation/documentation/spezifoundation) |

### SpeziLocalization

The `SpeziLocalization` target adds localization utilities on top of Foundation:
- `Bundle` extensions for looking up strings across multiple tables and for explicit languages, with language-tag fallback (e.g., `en-GB` to `en`);
- `LocalizedFileResource` and `LocalizedFileResolution` for selecting the best-matching localized variant of a file (e.g., `Welcome+de-DE.md`) for a locale, regardless of where the files are stored;
- `LocalizationKey` and `LocalizationsDictionary` for keying values by language and region, with fuzzy matching on lookup.

### SpeziFoundation in the Spezi Ecosystem

Most Spezi modules build on SpeziFoundation. Some examples of how its components are used:
- [Spezi](https://github.com/StanfordSpezi/Spezi) stores the values that modules provide and collect in a shared repository (`SpeziStorage` is a `ValueRepository<SpeziAnchor>`), and uses `AsyncSemaphore`, `withTimeout`, and cancelable child tasks to coordinate remote notification registration and the lifecycle of service modules.
- [SpeziAccount](https://github.com/StanfordSpezi/SpeziAccount) models account details as a `SendableValueRepository`: every `AccountKey` (user id, email address, etc.) is a `KnowledgeSource` anchored to `AccountAnchor`, which lets other packages define additional account keys.
- [SpeziScheduler](https://github.com/StanfordSpezi/SpeziScheduler) stores task and outcome metadata in shared repositories, and uses `AsyncSemaphore` when scheduling notifications.
- [SpeziHealthKit](https://github.com/StanfordSpezi/SpeziHealthKit) keeps query results in `OrderedArray`s, runs bulk exports through `withManagedTaskQueue`, guards caches with `RWLock` and `RecursiveRWLock`, and wraps HealthKit calls that can raise Objective-C exceptions in `catchingNSException`.
- [SpeziBluetooth](https://github.com/StanfordSpezi/SpeziBluetooth) bridges CoreBluetooth's delegate callbacks into async/await with `ManagedAsynchronousAccess`, and uses `RWLock`, `AsyncSemaphore`, `withTimeout`, and `DataDescriptor` for device discovery.
- [SpeziLLM](https://github.com/StanfordSpezi/SpeziLLM) limits concurrent inference jobs with `AsyncSemaphore` and protects its queue state with `RWLock`.
- [SpeziViews](https://github.com/StanfordSpezi/SpeziViews) renders `MarkdownDocument`s in its `MarkdownView` and re-exports SpeziLocalization; [SpeziConsent](https://github.com/StanfordSpezi/SpeziConsent) builds its consent documents on `MarkdownDocument`.
- [SpeziStudy](https://github.com/StanfordSpezi/SpeziStudy) resolves the localized files of a study bundle with `LocalizedFileResource` and `LocalizationKey`.


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
