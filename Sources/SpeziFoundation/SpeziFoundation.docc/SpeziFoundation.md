# ``SpeziFoundation``

<!--
#
# This source file is part of the Stanford Spezi open-source project
#
# SPDX-FileCopyrightText: 2022 Stanford University and the project authors (see CONTRIBUTORS.md)
#
# SPDX-License-Identifier: MIT
#       
-->

Spezi Foundation provides a base layer of functionality useful in many applications, including fundamental types, algorithms, extensions, and data structures.

## Topics

### Data Structures
- <doc:Shared-Repository>
- ``OrderedArray``

### Calendar and Time Zone handling
- <doc:Calendar>

### Sequence and Collection utilities
- <doc:CollectionAlgorithms>

### Concurrency
- ``RWLock``
- ``RecursiveRWLock``
- ``AsyncSemaphore``
- ``ManagedAsynchronousAccess``
- ``runOrScheduleOnMainActor(_:)``
- ``CancelableTaskHandle``
- ``_Concurrency/DiscardingTaskGroup/addCancelableTask(_:)``

### Encoders and Decoders
- ``TopLevelEncoder``
- ``TopLevelDecoder``

### Generic Result Builders
- ``RangeReplaceableCollectionBuilder``
- ``ArrayBuilder``
- ``SetBuilder``
- ``Swift/Array/init(build:)``
- ``Swift/Set/init(build:)``

### Introspection
- ``AnyArray``
- ``AnyOptional``

### Data
- ``DataDescriptor``

### Timeout
- ``TimeoutError``
- ``withTimeout(of:perform:)``

### Objective-C Exception Handling
- ``catchingNSException(_:)``
- ``CaughtNSException``

### System Programming Interfaces
- <doc:SPI>
