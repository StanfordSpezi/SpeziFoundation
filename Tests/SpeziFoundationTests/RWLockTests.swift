//
// This source file is part of the Stanford Spezi open-source project
//
// SPDX-FileCopyrightText: 2024 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import Dispatch
import SpeziFoundation
import XCTest


final class RWLockTests: XCTestCase {
    /// Two readers must be able to hold the lock *at the same time*.
    ///
    /// `testConcurrentReads` below cannot distinguish a shared read lock from an exclusive one: two
    /// 100ms sleeps fit inside its 1s timeout whether they overlap or serialize. This test instead has
    /// each reader wait for the *other* to be inside the lock before either releases, so it can only
    /// complete if both hold the lock simultaneously — and deadlocks (caught by the timeout) if the
    /// lock is exclusive.
    ///
    /// It uses two dedicated `Thread`s rather than `DispatchQueue.global()`: GCD does not guarantee a
    /// second pooled thread starts while the first is blocked, so on core-constrained runners (watchOS
    /// and tvOS simulators) the two readers could fail to overlap even with a correct lock. Two explicit
    /// threads are always both scheduled.
    func testConcurrentReadsActuallyOverlap() {
        let lock = RWLock()
        let firstHasLock = DispatchSemaphore(value: 0)
        let secondHasLock = DispatchSemaphore(value: 0)
        let firstDone = self.expectation(description: "First reader finished")
        let secondDone = self.expectation(description: "Second reader finished")

        Thread.detachNewThread {
            lock.withReadLock {
                firstHasLock.signal()
                // Only returns if the second reader can take the lock while this one still holds it.
                XCTAssertEqual(secondHasLock.wait(timeout: .now() + 5), .success)
            }
            firstDone.fulfill()
        }
        Thread.detachNewThread {
            lock.withReadLock {
                secondHasLock.signal()
                XCTAssertEqual(firstHasLock.wait(timeout: .now() + 5), .success)
            }
            secondDone.fulfill()
        }

        wait(for: [firstDone, secondDone], timeout: 10)
    }

    func testConcurrentReads() {
        let lock = RWLock()
        let expectation1 = self.expectation(description: "First read")
        let expectation2 = self.expectation(description: "Second read")

        Task.detached {
            lock.withReadLock {
                usleep(100_000) // Simulate read delay (200ms)
                expectation1.fulfill()
            }
        }

        Task.detached {
            lock.withReadLock {
                usleep(100_000) // Simulate read delay (200ms)
                expectation2.fulfill()
            }
        }

        wait(for: [expectation1, expectation2], timeout: 1.0)
    }

    func testWriteBlocksOtherWrites() {
        let lock = RWLock()
        let expectation1 = self.expectation(description: "First write")
        let expectation2 = self.expectation(description: "Second write")

        Task.detached {
            lock.withWriteLock {
                usleep(200_000) // Simulate write delay (200ms)
                expectation1.fulfill()
            }
        }

        Task.detached {
            try await Task.sleep(for: .milliseconds(100))
            lock.withWriteLock {
                expectation2.fulfill()
            }
        }

        wait(for: [expectation1, expectation2], timeout: 1.0)
    }

    func testWriteBlocksReads() {
        let lock = RWLock()
        let expectation1 = self.expectation(description: "Write")
        let expectation2 = self.expectation(description: "Read")

        Task.detached {
            lock.withWriteLock {
                usleep(200_000) // Simulate write delay (200ms)
                expectation1.fulfill()
            }
        }

        Task.detached {
            try await Task.sleep(for: .milliseconds(100))
            lock.withReadLock {
                expectation2.fulfill()
            }
        }

        wait(for: [expectation1, expectation2], timeout: 1.0)
    }

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
    func testIsWriteLocked() {
#if canImport(Darwin)
        let lock = RWLock()

        Task.detached {
            lock.withWriteLock {
                XCTAssertTrue(lock.isWriteLocked())
                usleep(100_000) // Simulate write delay (100ms)
            }
        }

        usleep(50_000) // Give the other thread time to lock (50ms)
        XCTAssertFalse(lock.isWriteLocked())
#endif
    }


    func testMultipleLocksAcquired() {
        let lock1 = RWLock()
        let lock2 = RWLock()
        let expectation1 = self.expectation(description: "Read")

        Task.detached {
            lock1.withReadLock {
                lock2.withReadLock {
                    expectation1.fulfill()
                }
            }
        }

        wait(for: [expectation1], timeout: 1.0)
    }


    func testConcurrentReadsRecursive() {
        let lock = RecursiveRWLock()
        let expectation1 = self.expectation(description: "First read")
        let expectation2 = self.expectation(description: "Second read")

        Task.detached {
            lock.withReadLock {
                usleep(100_000) // Simulate read delay 100 ms
                expectation1.fulfill()
            }
        }

        Task.detached {
            lock.withReadLock {
                usleep(100_000) // Simulate read delay 100ms
                expectation2.fulfill()
            }
        }

        wait(for: [expectation1, expectation2], timeout: 1.0)
    }

    func testWriteBlocksOtherWritesRecursive() {
        let lock = RecursiveRWLock()
        let expectation1 = self.expectation(description: "First write")
        let expectation2 = self.expectation(description: "Second write")

        Task.detached {
            lock.withWriteLock {
                usleep(200_000) // Simulate write delay 200ms
                expectation1.fulfill()
            }
        }

        Task.detached {
            try await Task.sleep(for: .milliseconds(100))
            lock.withWriteLock {
                expectation2.fulfill()
            }
        }

        wait(for: [expectation1, expectation2], timeout: 1.0)
    }

    func testWriteBlocksReadsRecursive() {
        let lock = RecursiveRWLock()
        let expectation1 = self.expectation(description: "Write")
        let expectation2 = self.expectation(description: "Read")

        Task.detached {
            lock.withWriteLock {
                usleep(200_000) // Simulate write delay 200 ms
                expectation1.fulfill()
            }
        }

        Task.detached {
            try await Task.sleep(for: .milliseconds(100))
            lock.withReadLock {
                expectation2.fulfill()
            }
        }

        wait(for: [expectation1, expectation2], timeout: 1.0)
    }

    func testMultipleLocksAcquiredRecursive() {
        let lock1 = RecursiveRWLock()
        let lock2 = RecursiveRWLock()
        let expectation1 = self.expectation(description: "Read")

        Task.detached {
            lock1.withReadLock {
                lock2.withReadLock {
                    expectation1.fulfill()
                }
            }
        }

        wait(for: [expectation1], timeout: 1.0)
    }

    func testRecursiveReadReadAcquisition() {
        let lock = RecursiveRWLock()
        let expectation1 = self.expectation(description: "Read")

        Task.detached {
            lock.withReadLock {
                lock.withReadLock {
                    expectation1.fulfill()
                }
            }
        }

        wait(for: [expectation1], timeout: 1.0)
    }

    func testRecursiveWriteRecursiveAcquisition() {
        let lock = RecursiveRWLock()
        let expectation1 = self.expectation(description: "Read")
        let expectation2 = self.expectation(description: "ReadWrite")
        let expectation3 = self.expectation(description: "WriteRead")
        let expectation4 = self.expectation(description: "Write")

        let expectation5 = self.expectation(description: "Race")

        Task.detached {
            lock.withWriteLock {
                usleep(50_000) // Simulate write delay 50 ms
                lock.withReadLock {
                    expectation1.fulfill()
                    usleep(200_000) // Simulate write delay 200 ms
                    lock.withWriteLock {
                        expectation2.fulfill()
                    }
                }

                lock.withWriteLock {
                    usleep(200_000) // Simulate write delay 200 ms
                    lock.withReadLock {
                        expectation3.fulfill()
                    }
                    expectation4.fulfill()
                }
            }
        }

        Task.detached {
            await withDiscardingTaskGroup { group in
                for _ in 0..<10 {
                    group.addTask {
                        // random sleep up to 50 ms
                        try? await Task.sleep(nanoseconds: UInt64.random(in: 0...50_000_000))
                        lock.withWriteLock {
                            _ = usleep(100)
                        }
                    }
                }
            }

            expectation5.fulfill()
        }

        wait(for: [expectation1, expectation2, expectation3, expectation4, expectation5], timeout: 20.0)
    }
}
