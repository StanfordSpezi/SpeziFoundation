//
// This source file is part of the Stanford Spezi open-source project
//
// SPDX-FileCopyrightText: 2022 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import Foundation


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
    /// Creates a localized version of the instance conforming to `StringProtocol`.
    ///
    /// String literals (`StringLiteralType`) and `String.LocalizationValue` instances are tried to be localized using the provided bundle.
    /// `String` instances are not localized. You have to manually localize a `String` instance using `String(localized:)`.
    @available(*, deprecated, message: "Prefer explicitly using LocalizedStringResource.")
    public func localized(_ bundle: Bundle? = nil) -> LocalizedStringResource {
        let bundleDescription = bundle.map { LocalizedStringResource.BundleDescription.atURL(from: $0) } ?? .main
        switch self {
        case let text as String.LocalizationValue:
            return LocalizedStringResource(text, bundle: bundleDescription)
        case let text as StringLiteralType:
            return LocalizedStringResource(String.LocalizationValue(text), bundle: bundleDescription)
        default:
            return LocalizedStringResource(stringLiteral: String(self))
        }
    }
}
