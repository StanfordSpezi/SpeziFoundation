//
// This source file is part of the Stanford Spezi open-source project
//
// SPDX-FileCopyrightText: 2025 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import SpeziFoundation
import SwiftUI


@main
struct UITestsApp: App {
    var body: some Scene {
        WindowGroup {
            NavigationStack {
                Form {
                    content
                }
                .formStyle(.grouped)
            }
        }
    }
    
    @ViewBuilder private var content: some View {
        Section {
            makeRow("Is running in Sandbox", value: ProcessInfo.isRunningInSandbox)
            makeRow("Is running in XCTest", value: ProcessInfo.isRunningInXCTest)
        }
    }
    
    func makeRow(_ title: String, value: some CustomStringConvertible) -> some View {
        HStack {
            Text(title)
            Spacer()
            Text(value.description)
                .foregroundStyle(.secondary)
        }
        .accessibilityElement(children: .combine)
        .accessibilityValue("\(title), \(value.description)")
    }
}
