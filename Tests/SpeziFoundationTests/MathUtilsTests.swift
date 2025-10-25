//
//  MathUtilsTests.swift
//  SpeziFoundation
//
//  Created by Philipp Nagy on 25.10.25.
//


import Testing
import SpeziFoundation

@Suite
struct MathUtilsTests {
#if os(Linux)
    @Test
    func add() {
        #expect(MathUtils.add(2, 3) == 5)
        #expect(MathUtils.add(-1, 1) == 0)
    }

    @Test
    func factorial() {
        #expect(MathUtils.factorial(0) == 1)
        #expect(MathUtils.factorial(5) == 120)
        #expect(MathUtils.factorial(-3) == 0)
    }

    @Test
    func isPrime() {
        #expect(MathUtils.isPrime(0) == false)
        #expect(MathUtils.isPrime(1) == false)
        #expect(MathUtils.isPrime(2))
        #expect(MathUtils.isPrime(13))
        #expect(MathUtils.isPrime(12) == false)
    }
#endif
}
