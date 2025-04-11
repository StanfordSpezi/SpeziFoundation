//
// This source file is part of the Stanford Spezi open-source project
//
// SPDX-FileCopyrightText: 2025 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import Foundation
import XCTest
import XCTestExtensions


class TestAppUITests: XCTestCase {
    @MainActor
    func testRuntimeContext() throws {
        let app = XCUIApplication()
        app.launch()
        XCTAssertTrue(app.staticTexts["Is running in Sandbox, true"].waitForExistence(timeout: 1))
        XCTAssertTrue(app.staticTexts["Is running in XCTest, false"].waitForExistence(timeout: 1))
    }
}
