//
// This source file is part of the Stanford Spezi open-source project
//
// SPDX-FileCopyrightText: 2025 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

public import Foundation
#if canImport(zlib)
import zlib
#elseif canImport(CZlib)
import CZlib
#else
#error("No zlib module found. On Linux ensure that you have zlib1g-dev installed.")
#endif

/// A wrapper around the `zlib` compression library
public enum Zlib: CompressionAlgorithm {
    public typealias DecompressionError = CompressionError
    
    public enum CompressionError: Error {
        case invalidInput
        case notEnoughMemory
        case other(Int32)
    }
    
    public static func compress(_ input: borrowing some Collection<UInt8>) throws(CompressionError) -> Data {
        let inputCount = input.count
        let result: Result<Data, CompressionError>? = input.withContiguousStorageIfAvailable { inputBuffer in
            precondition(inputBuffer.count == inputCount)
            guard let inputBufferPtr = inputBuffer.baseAddress else {
                return .failure(.invalidInput)
            }
            let outputBufferSize = compressBound(UInt(inputBuffer.count))
            let outputBuffer: UnsafeMutablePointer<UInt8> = .allocate(capacity: Int(outputBufferSize))
            var compressedSize: UInt = outputBufferSize
            let status = compress2(outputBuffer, &compressedSize, inputBufferPtr, UInt(inputBuffer.count), 9)
            switch status {
            case Z_OK:
                return .success(Data(bytesNoCopy: outputBuffer, count: Int(compressedSize), deallocator: .free))
            case Z_MEM_ERROR:
                outputBuffer.deallocate()
                return .failure(.notEnoughMemory)
            case Z_BUF_ERROR:
                // shouldn't happen, since we use compressBound() to determine the expected output buffer size...
                fallthrough // swiftlint:disable:this no_fallthrough_only
            case Z_STREAM_ERROR:
                // should be unreachable, since we only ever pass valid levels (ie, 0-9) into compress2...
                fallthrough // swiftlint:disable:this no_fallthrough_only
            default:
                // should also be unreachable, since the switch above covers all status codes mentioned in the zlib documentation.
                outputBuffer.deallocate()
                return .failure(.other(status))
            }
        }
        if let result {
            return try result.get()
        } else {
            throw .invalidInput
        }
    }
    
    
    public static func decompress(_ input: borrowing some Collection<UInt8>) throws(DecompressionError) -> Data {
        try decompress(input, expectedOutputLength: input.count)
    }
    
    private static func decompress(_ input: borrowing some Collection<UInt8>, expectedOutputLength: Int) throws(DecompressionError) -> Data {
        let inputCount = input.count
        let result: Result<Data, CompressionError>? = input.withContiguousStorageIfAvailable { inputBuffer in
            precondition(inputBuffer.count == inputCount)
            guard let inputBufferPtr = inputBuffer.baseAddress else {
                return .failure(.invalidInput)
            }
            let outputBufferSize = UInt(expectedOutputLength)
            let outputBuffer: UnsafeMutablePointer<UInt8> = .allocate(capacity: Int(outputBufferSize))
            var decompressedSize: UInt = outputBufferSize
            let status = uncompress(outputBuffer, &decompressedSize, inputBufferPtr, UInt(inputBuffer.count))
            switch status {
            case Z_OK:
                return .success(Data(bytesNoCopy: outputBuffer, count: Int(decompressedSize), deallocator: .free))
            case Z_MEM_ERROR:
                outputBuffer.deallocate()
                return .failure(.notEnoughMemory)
            case Z_BUF_ERROR:
                // if we end up in here, out output buffer was too small.
                fallthrough // swiftlint:disable:this no_fallthrough_only
            case Z_STREAM_ERROR:
                // should be unreachable, since we only ever pass valid levels (ie, 0-9) into compress2...
                fallthrough // swiftlint:disable:this no_fallthrough_only
            default:
                // should also be unreachable, since the switch above covers all status codes mentioned in the zlib documentation.
                outputBuffer.deallocate()
                return .failure(.other(status))
            }
        }
        guard let result else {
            throw .invalidInput
        }
        do {
            return try result.get()
        } catch DecompressionError.other(Z_BUF_ERROR) {
            return try Self.decompress(input, expectedOutputLength: expectedOutputLength + (expectedOutputLength / 2))
        } catch {
            throw error
        }
    }
}
