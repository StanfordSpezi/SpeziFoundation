//
// This source file is part of the Stanford Spezi open-source project
//
// SPDX-FileCopyrightText: 2025 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//


import SpeziFoundation
import XCTest


@globalActor
actor TestActor: GlobalActor {
    let queue = DispatchQueue(label: "Queueeee") as! DispatchSerialQueue
    nonisolated var unownedExecutor: UnownedSerialExecutor {
        queue.asUnownedSerialExecutor()
    }
    static let shared = TestActor()
}


final class MainActorExecutionTests: XCTestCase {
    func testIfAlreadyRunningOnMainActor() {
        // XCTest by default runs all test cases on the main thread, ie the main queue, ie the main actor.
        dispatchPrecondition(condition: .onQueue(.main))
        var didRun = false
        RunOrScheduleOnMainActor {
            didRun = true
        }
        XCTAssertTrue(didRun)
    }
    
    @TestActor
    func testIfRunningOffTheMainActor() async {
        dispatchPrecondition(condition: .notOnQueue(.main))
        dispatchPrecondition(condition: .onQueue(TestActor.shared.queue))
        var didRun = false
        RunOrScheduleOnMainActor {
            didRun = true
        }
        XCTAssertFalse(didRun)
    }
}
