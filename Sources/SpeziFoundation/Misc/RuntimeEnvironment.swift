//
// This source file is part of the Stanford Spezi open-source project
//
// SPDX-FileCopyrightText: 2025 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

public import Foundation
#if os(macOS) || targetEnvironment(macCatalyst)
private import Security
#endif


extension ProcessInfo {
    /// Whether the application is currently running in a sandbox.
    ///
    /// This value will always be `true` when running on iOS, watchOS, visionOS, or tvOS.
    public static let isRunningInSandbox: Bool = {
    #if !(os(macOS) || targetEnvironment(macCatalyst))
        // If we're not running on macOS or macCatalyst, we're running on iOS/watchOS/visionOS/tvOS which always have a sandbox
        return true
    #else
        var `self`: SecCode?
        guard SecCodeCopySelf([], &self) == errSecSuccess else {
            return false
        }
        var codeSignInfo: CFDictionary?
        guard SecCodeCopySigningInformation(
            unsafeBitCast(self, to: SecStaticCode.self),
            SecCSFlags(rawValue: kSecCSDynamicInformation),
            &codeSignInfo
        ) == errSecSuccess else {
            return false
        }
        guard let codeSignInfo = codeSignInfo.map({ $0 as NSDictionary }),
              let entitlementsDict = codeSignInfo[kSecCodeInfoEntitlementsDict] as? NSDictionary else {
            return false
        }
        if let sandboxEntry = entitlementsDict["com.apple.security.app-sandbox"] as? NSNumber {
            return sandboxEntry.boolValue
        } else {
            return false
        }
    #endif
    }()
    
    
    /// Whether the application is currently being run as part of a XCTest.
    ///
    /// - Note: This value does **not** indicate whether the application is currently being tested; for example, it will be `false` for an app currently being UI-tested,
    /// since in that case the app itself will be running in a separate process from the actual test target (for which this value would be `true`).
    #if os(Linux)
    @available(*, unavailable, message: "isRunningInXCTest is not available on Linux")
    #endif
    public static var isRunningInXCTest: Bool {
        NSClassFromString("XCTestCase") != nil
    }
}
