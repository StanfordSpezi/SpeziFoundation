<!--
                  
This source file is part of the Stanford Spezi open-source project

SPDX-FileCopyrightText: 2022 Stanford University and the project authors (see CONTRIBUTORS.md)

SPDX-License-Identifier: MIT
             
-->

# SpeziFoundation

[![Build and Test](https://github.com/StanfordSpezi/SpeziFoundation/actions/workflows/build-and-test.yml/badge.svg)](https://github.com/StanfordSpezi/SpeziFoundation/actions/workflows/build-and-test.yml)
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


## Installation

The project can be added to your Xcode project or Swift Package using the [Swift Package Manager](https://github.com/apple/swift-package-manager).

**Xcode:** For an Xcode project, follow the instructions on [adding package dependencies to your app](https://developer.apple.com/documentation/xcode/adding-package-dependencies-to-your-app).

**Swift Package:** You can follow the [Swift Package Manager documentation about defining dependencies](https://github.com/apple/swift-package-manager/blob/main/Documentation/Usage.md#defining-dependencies) to add this project as a dependency to your Swift Package.


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
