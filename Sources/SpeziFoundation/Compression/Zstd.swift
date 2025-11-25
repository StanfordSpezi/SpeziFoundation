//
// This source file is part of the Stanford Spezi open-source project
//
// SPDX-FileCopyrightText: 2025 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

public import Foundation
public import libzstd

/// A wrapper around the `Zstd` compression library
public enum Zstd: CompressionAlgorithm {
    public typealias DecompressionError = CompressionError
    
    public enum CompressionError: Error {
        /// The input sequence didn't have an underlying contiguous storage
        case invalidInput
        case notEnoughMemory
        case other(ZSTD_ErrorCode)
    }
    
    /// The compression context
    @TaskLocal private static var cCtx: ZstdContext = .cctx()
    /// The decompression context
    @TaskLocal private static var dCtx: ZstdContext = .dctx()
    
    public static func compress(_ input: borrowing some Collection<UInt8>) throws(CompressionError) -> Data {
        let inputCount = input.count
        let result: Result<Data, CompressionError>? = input.withContiguousStorageIfAvailable { inputBuffer in
            assert(inputBuffer.count == inputCount)
            guard let inputBufferPtr = inputBuffer.baseAddress else {
                return .failure(.invalidInput)
            }
            let outputBufferSize = ZSTD_compressBound(inputBuffer.count)
            let outputBuffer: UnsafeMutablePointer<UInt8> = .allocate(capacity: outputBufferSize)
            let result = ZSTD_compressCCtx(Self.cCtx._ctx, outputBuffer, outputBufferSize, inputBufferPtr, inputCount, ZSTD_defaultCLevel())
            if ZSTD_isError(result) == 0 {
                return .success(Data(bytesNoCopy: outputBuffer, count: result, deallocator: .free))
            } else {
                switch ZSTD_getErrorCode(result) {
                case ZSTD_error_memory_allocation:
                    return .failure(.notEnoughMemory)
                case let errorCode:
                    return .failure(.other(errorCode))
                }
            }
        }
        guard let result else {
            // the input didn't have a contiguous storage representation
            throw .invalidInput
        }
        return try result.get()
    }
    
    
    public static func decompress(_ input: borrowing some Collection<UInt8>) throws(DecompressionError) -> Data {
        let inputCount = input.count
        let result: Result<Data, DecompressionError>? = input.withContiguousStorageIfAvailable { inputBuffer in
            guard let inputBufferPtr = inputBuffer.baseAddress else {
                return .failure(.invalidInput)
            }
            assert(inputBuffer.count == inputCount)
            switch ZSTD_getFrameContentSize(inputBufferPtr, inputCount) {
            case ZSTD_CONTENTSIZE_ERROR:
                // likely not compressed by Zstd
                return .failure(.invalidInput)
            case ZSTD_CONTENTSIZE_UNKNOWN:
                // could try to use streaming decompression for this at some point in the future
                return .failure(.invalidInput)
            case let contentSize:
                let contentSize = Int(contentSize)
                let outputBuffer: UnsafeMutablePointer<UInt8> = .allocate(capacity: contentSize)
                let result = ZSTD_decompressDCtx(Self.dCtx._ctx, outputBuffer, contentSize, inputBufferPtr, inputBuffer.count)
                if ZSTD_isError(result) == 0 {
                    return .success(Data(bytesNoCopy: outputBuffer, count: contentSize, deallocator: .free))
                } else {
                    switch ZSTD_getErrorCode(result) {
                    case ZSTD_error_memory_allocation:
                        return .failure(.notEnoughMemory)
                    case let errorCode:
                        return .failure(.other(errorCode))
                    }
                }
            }
        }
        guard let result else {
            // the input didn't have a contiguous storage representation
            throw .invalidInput
        }
        return try result.get()
    }
}


extension Zstd {
    private final class ZstdContext: @unchecked Sendable {
        let _ctx: OpaquePointer // swiftlint:disable:this identifier_name
        private let free: @Sendable (OpaquePointer) -> Int
        
        private init(ctx: OpaquePointer, free: @escaping @Sendable (OpaquePointer) -> Int) {
            self._ctx = ctx
            self.free = free
        }
        
        static func cctx() -> ZstdContext {
            ZstdContext(ctx: ZSTD_createCCtx(), free: ZSTD_freeCCtx)
        }
        
        static func dctx() -> ZstdContext {
            ZstdContext(ctx: ZSTD_createDCtx(), free: ZSTD_freeDCtx)
        }
        
        deinit {
            _ = free(_ctx)
        }
    }
}
