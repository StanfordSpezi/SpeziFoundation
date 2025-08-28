//
// This source file is part of the Stanford Spezi open-source project
//
// SPDX-FileCopyrightText: 2025 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import Foundation


/// A compression algorithm
public protocol CompressionAlgorithm {
    /// An error that can occur when compressing an input
    associatedtype CompressionError: Swift.Error
    /// An error that can occur when decompressing an input
    associatedtype DecompressionError: Swift.Error
    
    /// Compresses the input.
    static func compress(_ input: borrowing some Collection<UInt8>) throws(CompressionError) -> Data
    /// Decompresses the input.
    static func decompress(_ input: borrowing some Collection<UInt8>) throws(DecompressionError) -> Data
}


extension Collection<UInt8> {
    /// Compresses the sequence of bytes using the specified ``CompressionAlgorithm``
    public func compressed<Algorithm: CompressionAlgorithm>(using algorithm: Algorithm.Type) throws(Algorithm.CompressionError) -> Data {
        try algorithm.compress(self)
    }
    
    /// Decompresses the sequence of bytes using the specified ``CompressionAlgorithm``
    public func decompressed<Algorithm: CompressionAlgorithm>(using algorithm: Algorithm.Type) throws(Algorithm.DecompressionError) -> Data {
        try algorithm.decompress(self)
    }
}
