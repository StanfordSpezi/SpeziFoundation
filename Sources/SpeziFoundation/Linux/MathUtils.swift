//
//  MathUtils.swift
//  SpeziFoundation
//
//  Created by Philipp Nagy on 25.10.25.
//


public struct MathUtils {
    /// Adds two integers.
    public static func add(_ a: Int, _ b: Int) -> Int {
        return a + b
    }

    /// Returns the factorial of a number.
    public static func factorial(_ n: Int) -> Int {
        guard n >= 0 else { return 0 } // negative numbers not allowed
        if n == 0 { return 1 }
        return (1...n).reduce(1, *)
    }

    /// Determines if a number is prime.
    public static func isPrime(_ n: Int) -> Bool {
        guard n > 1 else { return false }
        for i in 2..<n {
            if n % i == 0 { return false }
        }
        return true
    }
}
