//
//  File.swift
//  SpeziFoundation
//
//  Created by Lukas Kollmer on 2024-12-27.
//

import Foundation



//extension UUID: Comparable {
////    @ThreadSafe2 private(set) static var totalNumComparisons: UInt64 = 0
//    
//    
//    /// Stolen from https://github.com/apple/swift-foundation/blob/71dfec2bc4a9b48f3575af4ceca7b6af65198fa9/Sources/FoundationEssentials/UUID.swift#L128
//    /// Does not necessarily produce meaningful results, the main point here is having some kind of stable (ie, deterministic) sorting on UUIDs.
//    public static func < (lhs: UUID, rhs: UUID) -> Bool {
////        Self.totalNumComparisons += 1
////        let result2 = measure(addDurationTo: &mTotalTimeSpentComparingUUIDs_me) { cmp_lt_me(lhs: lhs, rhs: rhs) }
////        let result1 = measure(addDurationTo: &mTotalTimeSpentComparingUUIDs_apple) { cmp_lt_apple(lhs: lhs, rhs: rhs) }
////        precondition(result1 == result2)
////        return result1
//        // TODO it seems that both of these implementations (_apple and _me) are functionally equivalent?
//        // (i had the check above on for like millions of comparisons and it never failed.)
//        // but somehow the _me version is way(!) faster than the _apple version???
//        return cmp_lt_me(lhs: lhs, rhs: rhs)
//    }
//    
//    
//    @_transparent
//    private static func cmp_lt_apple(lhs: UUID, rhs: UUID) -> Bool {
//        var leftUUID = lhs.uuid
//        var rightUUID = rhs.uuid
//        var result: Int = 0
//        var diff: Int = 0
//        withUnsafeBytes(of: &leftUUID) { leftPtr in
//            withUnsafeBytes(of: &rightUUID) { rightPtr in
//                for offset in (0 ..< MemoryLayout<uuid_t>.size).reversed() {
//                    diff = Int(leftPtr.load(fromByteOffset: offset, as: UInt8.self)) -
//                    Int(rightPtr.load(fromByteOffset: offset, as: UInt8.self))
//                    // Constant time, no branching equivalent of
//                    // if (diff != 0) {
//                    //     result = diff;
//                    // }
//                    result = (result & (((diff - 1) & ~diff) >> 8)) | diff
//                }
//            }
//        }
//        return result < 0
//    }
//    
//    
//    @_transparent
//    private static func cmp_lt_me(lhs: UUID, rhs: UUID) -> Bool {
//        return withUnsafeBytes(of: lhs.uuid) { lhsUUID -> Bool in
//            return withUnsafeBytes(of: rhs.uuid) { rhsUUID -> Bool in
//                for idx in 0..<MemoryLayout<uuid_t>.size {
//                    let lhs = lhsUUID[idx]
//                    let rhs = rhsUUID[idx]
//                    if lhs < rhs {
//                        return true
//                    } else if lhs > rhs {
//                        return false
//                    } else {
//                        continue
//                    }
//                }
//                return false // all bytes are equal
//            }
//        }
//    }
//}
