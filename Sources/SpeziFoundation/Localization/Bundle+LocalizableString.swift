//
// This source file is part of the Stanford Spezi open-source project
//
// SPDX-FileCopyrightText: 2025 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import Algorithms
import Foundation


extension Bundle {
    /// The localization table in which a lookup should take place.
    public enum LocalizationLookupTable: Hashable, Sendable {
        /// The `Localizable.strings` table.
        case `default`
        /// A custom `{name}.strings` table.
        case custom(_ name: String)
        
        /// A String representation of the table, compatible with `Bundle`'s localization APIs.
        fileprivate var stringValue: String? {
            switch self {
            case .default:
                nil
            case .custom(let name):
                name
            }
        }
    }
    
    
    public func preferredLocalizations(from preferences: [Locale.Language]) -> [Locale.Language] {
        Bundle.preferredLocalizations(
            from: self.localizations,
            forPreferences: preferences.map(\.minimalIdentifier)
        )
        .map { .init(identifier: $0) }
    }
    
    /// Looks up the localized version of a string in multiple tables, returning the first match.
    ///
    /// - parameter key: the localization key to look up a value for.
    /// - parameter tables: the tables in which the lookup should be performed.
    /// - returns: a localized version of the string, obtained from the first table that contained an entry for `key`.
    fileprivate func localizedString(forKey key: String, tables: [LocalizationLookupTable]) -> String? {
        let notFound = "NOT_FOUND"
        return (tables.isEmpty ? [.default] : tables).lazy
            .map { self.localizedString(forKey: key, value: notFound, table: $0.stringValue) }
            .first { $0 != notFound }
    }
    
    public func localizedString( // swiftlint:disable:this missing_docs
        forKey key: String,
        tables: [LocalizationLookupTable],
        localizations: [Locale.Language]
    ) -> String? {
        if #available(macOS 15.4, iOS 18.4, tvOS 18.4, watchOS 11.4, visionOS 2.4, *) {
            let notFound = "NOT_FOUND"
            return localizations.lazy.compactMap { lang in
                (tables.isEmpty ? [.default] : tables).lazy
                    .map { self.localizedString(forKey: key, value: notFound, table: $0.stringValue, localizations: [lang]) }
                    .first { $0 != notFound }
            }
            .first
        } else {
            return localizedStringForKeyFallback(key: key, tables: tables, localizations: localizations)
        }
    }
    
    // ideally this would be directly in the other function, but bc of the #available check we wouldn't be able to test it then.
    // NOTE: remove this when we increase our package deployment target to >= iOS 18.4!
    @_spi(Testing)
    public func localizedStringForKeyFallback( // swiftlint:disable:this missing_docs
        key: String,
        tables: [LocalizationLookupTable],
        localizations: [Locale.Language]
    ) -> String? {
        print("\n\n\(key)")
        let tables = tables.isEmpty ? [.default] : tables
        for language in preferredLocalizations(from: localizations) {
            print("lang: \(language.minimalIdentifier)")
            let candidateNames = [
                language.minimalIdentifier.replacingOccurrences(of: "-", with: "_"),
                language.minimalIdentifier.replacingOccurrences(of: "_", with: "-")
            ]
            guard let bundle = candidateNames.firstNonNil({ name -> Bundle? in
                self.url(forResource: name, withExtension: "lproj").flatMap { Bundle(url: $0) }
            }) else {
//                print("  skippping")
                continue
            }
//            guard let lproj = self.url(forResource: language.minimalIdentifier.replacingOccurrences(of: "-", with: "_"), withExtension: "lproj"),
//                  let bundle = Bundle(url: lproj) else {
//                print("  skippping")
//                continue
//            }
            if let title = bundle.localizedString(forKey: key, tables: tables) {
                return title
            }
        }
        if false, tables.contains(.default), let title = self.localizedString(forKey: key, tables: [.default]) {
            print("--> fallback")
            return title
        } else {
            return nil
        }
    }
}
