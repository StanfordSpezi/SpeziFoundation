//
// This source file is part of the Stanford Spezi open-source project
//
// SPDX-FileCopyrightText: 2025 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import Foundation


/// Runs or schedules a closure on the `MainActor`, depending on the current execution context.
/// If the function is already running on the `MainActor`, the closure will be invoked immediately.
/// If the function is not running on the `MainActor`, an invocation of the closure will be scheduled onto the `MainActor`.
public func RunOrScheduleOnMainActor(
    _ block: @MainActor @escaping () -> Void
) {
    if Thread.isMainThread {
        MainActor.assumeIsolated {
            block()
        }
    } else {
        Task { @MainActor in
            block()
        }
    }
}
