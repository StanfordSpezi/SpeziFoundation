//
// This source file is part of the Stanford Spezi open-source project
//
// SPDX-FileCopyrightText: 2024 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

@testable import SpeziFoundation
import XCTest


final class DataDescriptorTests: XCTestCase {
    func testEqualBitPattern() {
        let data1 = Data([0xFF, 0x00, 0xAA])
        let data2 = Data([0xFF, 0x00, 0xAA])
        let data3 = Data([0xFF, 0x00])
        let data4 = Data([0xFF, 0x00, 0xAA, 0x00])

        XCTAssertTrue(DataDescriptor.equalBitPattern(lhs: data1, rhs: data2), "Identical data should be equal")
        XCTAssertFalse(DataDescriptor.equalBitPattern(lhs: data1, rhs: data3), "Different length data should not be equal")
        XCTAssertTrue(DataDescriptor.equalBitPattern(lhs: data1, rhs: data4), "Additional zero bytes in rhs should be ignored")
    }

    func testDataDescriptorEquality_sameDataAndMask() {
        let data1 = Data([0xFF, 0x00, 0xAA])
        let mask1 = Data([0xFF, 0xFF, 0xFF])

        let descriptor1 = DataDescriptor(data: data1, mask: mask1)
        let descriptor2 = DataDescriptor(data: data1, mask: mask1)

        XCTAssertEqual(descriptor1, descriptor2, "Data descriptors with the same data and mask should be equal")
    }

    func testDataDescriptorEquality_differentDataSameMask() {
        let data1 = Data([0xFF, 0x00, 0xAA])
        let data2 = Data([0xFF, 0x00, 0xBB])
        let mask1 = Data([0xFF, 0xFF, 0xFF])

        let descriptor1 = DataDescriptor(data: data1, mask: mask1)
        let descriptor2 = DataDescriptor(data: data2, mask: mask1)

        XCTAssertNotEqual(descriptor1, descriptor2, "Data descriptors with different data but the same mask should not be equal")
    }

    func testDataDescriptorEquality_sameDataDifferentMask() {
        let data1 = Data([0xFF, 0x00, 0xAA])
        let mask1 = Data([0xFF, 0xFF, 0xFF])
        let mask2 = Data([0xFF, 0x00, 0xFF])

        let descriptor1 = DataDescriptor(data: data1, mask: mask1)
        let descriptor2 = DataDescriptor(data: data1, mask: mask2)

        XCTAssertNotEqual(descriptor1, descriptor2, "Data descriptors with the same data but different masks should not be equal")
    }

    func testDataDescriptorEquality_bitwiseAndComparison() {
        let data1 = Data([0xFF, 0x00, 0xAA])
        let data2 = Data([0xFF, 0x00, 0xAB])
        let mask1 = Data([0xFF, 0xFF, 0xFE])

        let descriptor1 = DataDescriptor(data: data1, mask: mask1)
        let descriptor2 = DataDescriptor(data: data2, mask: mask1)

        XCTAssertEqual(descriptor1, descriptor2, "Data descriptors with different data but the same masked result should be equal")
    }

    func testMatches_sameDataAndMask() {
        let data = Data([0xFF, 0x00, 0xAA])
        let mask = Data([0xFF, 0xFF, 0xFF])
        let descriptor = DataDescriptor(data: data, mask: mask)

        XCTAssertTrue(descriptor.matches(data), "Data should match exactly when both the data and the mask are identical.")
    }

    func testMatches_differentDataSameMask() {
        let data = Data([0xFF, 0x00, 0xAA])
        let otherData = Data([0xFF, 0x00, 0xAB])
        let mask = Data([0xFF, 0xFF, 0xFF])
        let descriptor = DataDescriptor(data: data, mask: mask)

        XCTAssertFalse(descriptor.matches(otherData), "Data should not match when the data differs and the mask is fully applied.")
    }

    func testMatches_maskedDataMatches() {
        let data = Data([0xFF, 0x00, 0xAA])
        let otherData = Data([0xFF, 0x00, 0xAB])
        let mask = Data([0xFF, 0xFF, 0xFE])  // Ignore the last bit of the last byte
        let descriptor = DataDescriptor(data: data, mask: mask)

        XCTAssertTrue(descriptor.matches(otherData), "Data should match if the masked bits are equal.")
    }

    func testMatches_dataShorterThanDescriptor() {
        let data = Data([0xFF, 0x00, 0xAA])
        let shorterData = Data([0xFF, 0x00])
        let mask = Data([0xFF, 0xFF, 0xFF])
        let descriptor = DataDescriptor(data: data, mask: mask)

        XCTAssertFalse(descriptor.matches(shorterData), "Data shorter than the descriptor should not match.")
    }

    func testMatches_dataLongerThanDescriptor() {
        let data = Data([0xFF, 0x00, 0xAA])
        let longerData = Data([0xFF, 0x00, 0xAA, 0x00])
        let mask = Data([0xFF, 0xFF, 0xFF])
        let descriptor = DataDescriptor(data: data, mask: mask)

        XCTAssertTrue(descriptor.matches(longerData), "Data longer than the descriptor should match as long as the relevant bits match.")
    }

    func testMatches_differentMasksSameData() {
        let data = Data([0xFF, 0x00, 0xAA])
        let maskedData = Data([0xFF, 0x00, 0xAB])
        let mask1 = Data([0xFF, 0xFF, 0xFE])  // Ignore the last bit of the last byte
        let mask2 = Data([0xFF, 0xFF, 0xFF])  // Fully consider all bits
        let descriptor1 = DataDescriptor(data: data, mask: mask1)
        let descriptor2 = DataDescriptor(data: data, mask: mask2)

        XCTAssertTrue(descriptor1.matches(maskedData), "Descriptor with mask that ignores last bit should match data with last bit difference.")
        XCTAssertFalse(descriptor2.matches(maskedData), "Descriptor with fully applied mask should not match data with last bit difference.")
    }

    func testMatches_ArraySlice() {
        let data = Data([0x02, 0x04, 0x05])

        let descriptor = DataDescriptor(data: Data([0xFF]), mask: Data([0b11001010]))

        let suffix = data[2...]
        XCTAssertFalse(descriptor.matches(suffix))
    }
}
