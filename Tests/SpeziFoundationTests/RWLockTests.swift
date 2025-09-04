//
// This source file is part of the Stanford Spezi open-source project
//
// SPDX-FileCopyrightText: 2024 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

@testable import SpeziFoundation
import XCTest
import Testing

@Suite
struct RWLockTests {
    
    @Test(.timeLimit(.minutes(1)))
    func testConcurrentReads() async {
        let lock = RWLock()
        await confirmation("First read") { expectation1 in
            await confirmation("Second read") { expectation2 in
                async let task1: Void = Task.detached {
                    lock.withReadLock {
                        usleep(100_000) // Simulate read delay (100ms)
                        expectation1()
                    }
                }.value
                
                async let task2: Void = Task.detached {
                    lock.withReadLock {
                        usleep(100_000) // Simulate read delay (100ms)
                        expectation2()
                    }
                }.value
                
                _ = await (task1, task2)
            }
        }
    }
    
    @Test(.timeLimit(.minutes(1)))
    func testWriteBlocksOtherWrites() async throws {
        let lock = RWLock()
        try await confirmation("First write") { expectation1 in
            try await confirmation("Second write") { expectation2 in
                async let task1: Void = Task.detached {
                    lock.withWriteLock {
                        usleep(200_000) // Simulate write delay (200ms)
                        expectation1()
                    }
                }.value
                
                async let task2: Void = Task.detached {
                    try await Task.sleep(for: .milliseconds(100))
                    lock.withWriteLock {
                        expectation2()
                    }
                }.value
                
                _ = try await (task1, task2)
            }
        }
    }
    
    @Test(.timeLimit(.minutes(1)))
    func testWriteBlocksReads() async throws {
        let lock = RWLock()
        try await confirmation("Write") { expectation1 in
            try await confirmation("Read") { expectation2 in
                async let task1: Void = Task.detached {
                    lock.withWriteLock {
                        usleep(200_000) // Simulate write delay (200ms)
                        expectation1()
                    }
                }.value
                
                async let task2: Void = Task.detached {
                    try await Task.sleep(for: .milliseconds(100))
                    lock.withReadLock {
                        expectation2()
                    }
                }.value
                
                _ = try await (task1, task2)
            }
        }
    }
    
    #if !canImport(Darwin)
    // This test is temporarily disabled on Linux.
    //
    // Reason: `lock.isWriteLocked()` behaves differently between Glibc (Linux) and macOS.
    // On macOS, `pthread_rwlock_trywrlock()` returns `EDEADLK` when the calling thread
    // already owns the lock, which makes `isWriteLocked()` work as expected.
    //
    // On Linux (glibc), `pthread_rwlock_trywrlock()` instead returns `EBUSY` in the same
    // scenario (only `pthread_rwlock_wrlock()` can return `EDEADLK`)
    //
    // To make this portable, `RWLock` would need to explicitly track ownership
    // of the lock by the current thread.
    //
    // See
    // - https://linux.die.net/man/3/pthread_rwlock_trywrlock
    // - https://developer.apple.com/library/archive/documentation/System/Conceptual/ManPages_iPhoneOS/man3/pthread_rwlock_trywrlock.3.html
    @Test(.disabled())
    #else
    @Test
    #endif
    func testIsWriteLocked() {
        let lock = RWLock()
    
        Task.detached {
            lock.withWriteLock {
                #expect(lock.isWriteLocked())
                usleep(100_000) // Simulate write delay (100ms)
            }
        }
        
        usleep(50_000) // Give the other thread time to lock (50ms)
        #expect(!lock.isWriteLocked())
    }
    
    @Test
    func testMultipleLocksAcquired() async {
        let lock1 = RWLock()
        let lock2 = RWLock()
        
        await confirmation("Read") { expectation1 in
            async let task: Void = Task.detached {
                lock1.withReadLock {
                    lock2.withReadLock {
                        expectation1()
                    }
                }
            }.value
            
            await task
        }
    }

    @Test(.timeLimit(.minutes(1)))
    func testConcurrentReadsRecursive() async {
        let lock = RecursiveRWLock()
        await confirmation("First read") { expectation1 in
            await confirmation("Second read") { expectation2 in
                async let task1: Void = Task.detached {
                    lock.withReadLock {
                        usleep(100_000) // Simulate read delay 100 ms
                        expectation1()
                    }
                }.value
                
                async let task2: Void = Task.detached {
                    lock.withReadLock {
                        usleep(100_000) // Simulate read delay 100ms
                        expectation2()
                    }
                }.value
                
                _ = await (task1, task2)
            }
        }
    }
    
    @Test(.timeLimit(.minutes(1)))
    func testWriteBlocksOtherWritesRecursive() async throws {
        let lock = RecursiveRWLock()
        try await confirmation("First write") { expectation1 in
            try await confirmation("Second write") { expectation2 in
                async let task1: Void = Task.detached {
                    lock.withWriteLock {
                        usleep(200_000) // Simulate write delay 200ms
                        expectation1()
                    }
                }.value
                    
                async let task2: Void = Task.detached {
                    try await Task.sleep(for: .milliseconds(100))
                    lock.withWriteLock {
                        expectation2()
                    }
                }.value
                    
                _ = try await (task1, task2)
            }
        }
    }
    
    @Test(.timeLimit(.minutes(1)))
    func testWriteBlocksReadsRecursive() async throws {
        let lock = RecursiveRWLock()
        try await confirmation("Write") { expectation1 in
            try await confirmation("Read") { expectation2 in
                async let task1: Void = Task.detached {
                    lock.withWriteLock {
                        usleep(200_000) // Simulate write delay 200 ms
                        expectation1()
                    }
                }.value
                
                async let task2: Void = Task.detached {
                    try await Task.sleep(for: .milliseconds(100))
                    lock.withReadLock {
                        expectation2()
                    }
                }.value
                
                _ = try await (task1, task2)
            }
        }
    }

    @Test(.timeLimit(.minutes(1)))
    func testMultipleLocksAcquiredRecursive() async {
        let lock1 = RecursiveRWLock()
        let lock2 = RecursiveRWLock()

        await confirmation("Read") { expectation1 in
            async let task: Void = Task.detached {
                lock1.withReadLock {
                    lock2.withReadLock {
                        expectation1()
                    }
                }
            }.value
            
            await task
        }
    }
    
    @Test(.timeLimit(.minutes(1)))
    func testRecursiveReadReadAcquisition() async {
        let lock = RecursiveRWLock()

        await confirmation("Read") { expectation1 in
            async let task: Void = Task.detached {
                lock.withReadLock {
                    lock.withReadLock {
                        expectation1()
                    }
                }
            }.value
            
            await task
        }
    }
    
    @Test(.timeLimit(.minutes(1)))
    func testRecursiveWriteRecursiveAcquisition() async {
        let lock = RecursiveRWLock()
        await confirmation("Write") { expectation1 in
            await confirmation("ReadWrite") { expectation2 in
                await confirmation("WriteRead") { expectation3 in
                    await confirmation("Write") { expectation4 in
                        await confirmation("Race") { expectation5 in
                            
                            async let task1: Void = Task.detached {
                                lock.withWriteLock {
                                    usleep(50_000) // Simulate write delay 50 ms
                                    lock.withReadLock {
                                        expectation1()
                                        usleep(
                                            200_000
                                        ) // Simulate write delay 200 ms
                                        lock.withWriteLock {
                                            expectation2()
                                        }
                                    }
                        
                                    lock.withWriteLock {
                                        usleep(
                                            200_000
                                        ) // Simulate write delay 200 ms
                                        lock.withReadLock {
                                            expectation3()
                                        }
                                        expectation4()
                                    }
                                }
                            }.value
                        
                            async let task2: Void = Task.detached {
                                await withDiscardingTaskGroup { group in
                                    for _ in 0..<10 {
                                        group.addTask {
                                            // random sleep up to 50 ms
                                            try? await Task
                                                .sleep(
                                                    nanoseconds: UInt64
                                                        .random(
                                                            in: 0...50_000_000
                                                        )
                                                )
                                            lock.withWriteLock {
                                                _ = usleep(100)
                                            }
                                        }
                                    }
                                }
                        
                                expectation5()
                            }.value
                        
                            _ = await (task1, task2)
                        }
                    }
                }
            }
        }
    }
}

