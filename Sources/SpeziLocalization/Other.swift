//
// This source file is part of the Stanford Spezi open-source project
//
// SPDX-FileCopyrightText: 2022 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

public import Foundation


extension LocalizedStringResource.BundleDescription {
    /// Convenience method to create a `BundleDescription.atURL()` from a given Bundle instance.
    /// - Parameter bundle: The Bundle instance to retrieve the Bundle URL from.
    public static func atURL(from bundle: Bundle) -> LocalizedStringResource.BundleDescription {
        .atURL(bundle.bundleURL)
    }
}


extension LocalizedStringResource {
    /// Creates a localized `String` from the given `LocalizedStringResource`.
    /// - Parameter locale: Specifies an override locale.
    /// - Returns: The localized string.
    public func localizedString(for locale: Locale? = nil) -> String {
        if let locale {
            var resource = self
            resource.locale = locale
            return String(localized: resource)
        }
        return String(localized: self)
    }
}


extension StringProtocol {
    @_documentation(visibility: internal)
    @available(*, deprecated, message: "Prefer explicitly using LocalizedStringResource.")
    public func localized(_: Bundle? = nil) -> LocalizedStringResource { // swiftlint:disable:this missing_docs
        LocalizedStringResource(stringLiteral: String(self))
    }
}
