//
// This source file is part of the Stanford Spezi open-source project
//
// SPDX-FileCopyrightText: 2022 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

@_spi(APISupport) @testable import SpeziFoundation
import Testing


struct TestAnchor: RepositoryAnchor {}


protocol TestTypes: Equatable {
    typealias Anchor = TestAnchor // default anchor

    var value: Int { get }
}


struct TestStruct: KnowledgeSource, TestTypes {
    var value: Int
}


final class TestClass: KnowledgeSource, TestTypes, Sendable {
    let value: Int


    init(value: Int) {
        self.value = value
    }


    static func == (lhs: TestClass, rhs: TestClass) -> Bool {
        lhs.value == rhs.value
    }
}


enum TestKeyLike: KnowledgeSource {
    typealias Anchor = TestAnchor
    typealias Value = TestClass
}


struct DefaultedTestStruct: DefaultProvidingKnowledgeSource, TestTypes {
    static let defaultValue = DefaultedTestStruct(value: 0)
    var value: Int
}


struct ComputedTestStruct<Policy: ComputedKnowledgeSourceStoragePolicy, Repository>: KnowledgeSource, ComputedKnowledgeSource {
    typealias Anchor = TestAnchor
    typealias Value = Int
    typealias StoragePolicy = Policy

    static func compute(from repository: Repository) -> Int {
        MainActor.assumeIsolated {
            computedValue
        }
    }
}

struct ComputedDefaultTestStruct<Policy: ComputedKnowledgeSourceStoragePolicy, Repository>: ComputedKnowledgeSource, DefaultProvidingKnowledgeSource {
    typealias Anchor = TestAnchor
    typealias Value = Int
    typealias StoragePolicy = Policy

    static var defaultValue: Int {
        Issue.record("\(Self.self) access result in default value execution!")
        return -1
    }

    static func compute(from repository: Repository) -> Int {
        MainActor.assumeIsolated {
            computedValue
        }
    }
}


struct OptionalComputedTestStruct<Policy: ComputedKnowledgeSourceStoragePolicy, Repository>: OptionalComputedKnowledgeSource {
    typealias Anchor = TestAnchor
    typealias Value = Int
    typealias StoragePolicy = Policy

    static func compute(from repository: Repository) -> Int? {
        MainActor.assumeIsolated {
            optionalComputedValue
        }
    }
}


@MainActor var computedValue: Int = 3
@MainActor var optionalComputedValue: Int?


@MainActor
@Suite("Shared Repository Tests")
final class SharedRepositoryTests {
    typealias Repository = ValueRepository<TestAnchor>

    private var repository = Repository()

    private var readRepository: Repository {
        repository // non-mutating access
    }

    @MainActor
    init() async throws {
        self.repository = .init()
        computedValue = 3
        optionalComputedValue = nil
    }

    @Test
    func testIteration() {
        var repository = Repository()
        repository[TestStruct.self] = TestStruct(value: 3)

        for value in repository {
            #expect(value.anySource is TestStruct.Type)
            #expect(value.anyValue is TestStruct)
            #expect(value.anyValue as? TestStruct == TestStruct(value: 3))
        }
    }

    @Test
    func testDefaultSubscript() throws {
        repository[TestStruct.self, default: TestStruct(value: 56)].value = 23

        let value = try #require(repository[TestStruct.self])
        #expect(value.value == 23)
    }

    @Test
    func testSetAndGet() {
        // test basic insertion and retrieval
        let testStruct = TestStruct(value: 42)
        repository[TestStruct.self] = testStruct
        let contentOfStruct = readRepository[TestStruct.self]
        #expect(contentOfStruct == testStruct)

        // test overwrite and retrieval
        let newTestStruct = TestStruct(value: 24)
        repository[TestStruct.self] = newTestStruct
        let newContentOfStruct = readRepository[TestStruct.self]
        #expect(newContentOfStruct == newTestStruct)

        // test deletion
        repository[TestStruct.self] = nil
        let newerContentOfStruct = readRepository[TestStruct.self]
        #expect(newerContentOfStruct == nil)
    }

    @Test
    func testGetWithDefault() {
        let testStruct = DefaultedTestStruct(value: 42)

        // test global default
        let defaultStruct = readRepository[DefaultedTestStruct.self]
        #expect(defaultStruct == DefaultedTestStruct(value: 0))

        // test that it falls back to the regular KnowledgeSource subscript if expecting a optional type
        let regularSubscript = readRepository[DefaultedTestStruct.self] ?? testStruct
        #expect(regularSubscript == testStruct)
    }

    @Test
    func testContains() {
        let testStruct = TestStruct(value: 42)
        #expect(!readRepository.contains(TestStruct.self))

        repository[TestStruct.self] = testStruct
        #expect(readRepository.contains(TestStruct.self))

        repository[TestStruct.self] = nil
        #expect(!readRepository.contains(TestStruct.self))
    }

    @Test
    func testGetAllThatConformTo() {
        let testStruct = TestStruct(value: 42)
        repository[TestStruct.self] = testStruct
        let testClass = TestClass(value: 42)
        repository[TestClass.self] = testClass

        let testTypes = readRepository.collect(allOf: (any TestTypes).self)
        #expect(testTypes.count == 2)
        #expect(testTypes.allSatisfy { $0.value == 42 })
    }

    @Test
    func testMutationStruct() {
        let testStruct = TestStruct(value: 42)
        repository[TestStruct.self] = testStruct

        var contentOfStruct = readRepository[TestStruct.self]
        contentOfStruct?.value = 24
        #expect(testStruct.value == 42)
        #expect(contentOfStruct?.value == 24)
    }

    @Test
    func testKeyLikeKnowledgeSource() {
        let testClass = TestClass(value: 42)
        repository[TestKeyLike.self] = testClass

        let contentOfClass = readRepository[TestKeyLike.self]
        #expect(contentOfClass == testClass)
    }

    @Test
    func testComputedKnowledgeSourceComputedOnlyPolicy() {
        let value = repository[ComputedTestStruct<_AlwaysComputePolicy, Repository>.self]
        let optionalValue = repository[OptionalComputedTestStruct<_AlwaysComputePolicy, Repository>.self]

        #expect(value == computedValue)
        #expect(optionalValue == optionalComputedValue)

        // make sure computed knowledge sources with `AlwaysCompute` policy are re-computed
        computedValue = 5
        optionalComputedValue = 4

        let newValue = repository[ComputedTestStruct<_AlwaysComputePolicy, Repository>.self]
        let newOptionalValue = repository[OptionalComputedTestStruct<_AlwaysComputePolicy, Repository>.self]

        #expect(newValue == computedValue)
        #expect(newOptionalValue == optionalComputedValue)
    }

    @Test
    func testComputedKnowledgeSourceComputedOnlyPolicyReadOnly() {
        let repository = repository // read-only

        let value = repository[ComputedTestStruct<_AlwaysComputePolicy, Repository>.self]
        let optionalValue = repository[OptionalComputedTestStruct<_AlwaysComputePolicy, Repository>.self]

        #expect(value == computedValue)
        #expect(optionalValue == optionalComputedValue)

        // make sure computed knowledge sources with `AlwaysCompute` policy are re-computed
        computedValue = 5
        optionalComputedValue = 4

        let newValue = repository[ComputedTestStruct<_AlwaysComputePolicy, Repository>.self]
        let newOptionalValue = repository[OptionalComputedTestStruct<_AlwaysComputePolicy, Repository>.self]

        #expect(newValue == computedValue)
        #expect(newOptionalValue == optionalComputedValue)
    }

    @Test
    func testComputedKnowledgeSourceStorePolicy() {
        let value = repository[ComputedTestStruct<_StoreComputePolicy, Repository>.self]
        let optionalValue = repository[OptionalComputedTestStruct<_StoreComputePolicy, Repository>.self]

        #expect(value == computedValue)
        #expect(optionalValue == optionalComputedValue)

        // get call bypasses the compute call, so tests if it's really stored
        let getValue = repository.get(ComputedTestStruct<_StoreComputePolicy, Repository>.self)
        let getOptionalValue = repository.get(OptionalComputedTestStruct<_StoreComputePolicy, Repository>.self)

        #expect(getValue == computedValue)
        #expect(getOptionalValue == optionalComputedValue) // this is nil

        // make sure computed knowledge sources with `Store` policy are not re-computed
        computedValue = 5
        optionalComputedValue = 4

        let newValue = repository[ComputedTestStruct<_StoreComputePolicy, Repository>.self]
        let newOptionalValue = repository[OptionalComputedTestStruct<_StoreComputePolicy, Repository>.self]

        #expect(newValue == value)
        #expect(newOptionalValue == optionalComputedValue) // never stored as it was nil

        // last check if its really written now
        let writtenOptionalValue = repository.get(OptionalComputedTestStruct<_StoreComputePolicy, Repository>.self)
        #expect(writtenOptionalValue == optionalComputedValue)

        // check again that it doesn't change
        optionalComputedValue = nil
        #expect(repository[OptionalComputedTestStruct<_StoreComputePolicy, Repository>.self] == 4)
    }

    @Test
    func testComputedKnowledgeSourcePreferred() {
        let value = repository[ComputedDefaultTestStruct<_StoreComputePolicy, Repository>.self]
        #expect(value == computedValue)
    }
}
