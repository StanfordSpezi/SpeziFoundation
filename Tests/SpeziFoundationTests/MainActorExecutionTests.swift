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
    static let shared = TestActor()
    let queue = DispatchQueue(label: "Queueeee") as! DispatchSerialQueue // swiftlint:disable:this force_cast
    nonisolated var unownedExecutor: UnownedSerialExecutor {
        queue.asUnownedSerialExecutor()
    }
}


final class MainActorExecutionTests: XCTestCase {
    func testIfAlreadyRunningOnMainActor() {
        // XCTest by default runs all test cases on the main thread, ie the main queue, ie the main actor.
        dispatchPrecondition(condition: .onQueue(.main))
        var didRun = false
        runOrScheduleOnMainActor {
            didRun = true
        }
        XCTAssertTrue(didRun)
    }
    
    @TestActor
    func testIfRunningOffTheMainActor() async {
        dispatchPrecondition(condition: .notOnQueue(.main))
        dispatchPrecondition(condition: .onQueue(TestActor.shared.queue))
        let expectation = self.expectation(description: "ran on main actor")
        runOrScheduleOnMainActor {
            expectation.fulfill()
        }
        await fulfillment(of: [expectation])
    }
}
