//
// This source file is part of the Stanford Spezi open-source project
//
// SPDX-FileCopyrightText: 2022 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import SpeziFoundation
import SwiftUI


@main
struct UITestsApp: App {
    var body: some Scene {
        WindowGroup {
            Text(SpeziFoundation().stanford)
        }
    }
}
