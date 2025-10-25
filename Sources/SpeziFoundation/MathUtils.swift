//
//  MathUtils.swift
//  SpeziFoundation
//
//  Created by Philipp Nagy on 25.10.25.
//


import Foundation

/// Utility type for performing simple math operations.
public enum MathUtils {
    /// Adds two integers.
    public static func add(_ lhs: Int, _ rhs: Int) -> Int {
        lhs + rhs
    }

    /// Returns the factorial of a number.
    public static func factorial(of number: Int) -> Int {
        guard number >= 0 else {
            return 0
        }
        if number == 0 {
            return 1
        }
        return (1...number).reduce(1, *)
    }

    /// Determines if a number is prime.
    public static func isPrime(_ number: Int) -> Bool {
        guard number > 1 else {
            return false
        }
        for divisor in 2..<number where number.isMultiple(of: divisor) {
            return false
        }
        return true
    }
}
