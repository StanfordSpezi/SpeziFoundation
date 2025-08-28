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
    
    
    /// Returns the bundle's preferred languages, based on the provided array of languages.
    public func preferredLocalizations(from preferences: some Collection<Locale.Language>) -> [Locale.Language] {
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
    public func localizedString(forKey key: String, tables: [LocalizationLookupTable]) -> String? {
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
        let tables = tables.isEmpty ? [.default] : tables
        let localizations = preferredLocalizations(from: localizations)
        // we first look for and in each language's lproj bundle
        for language in localizations {
            let candidateNames = [
                language.minimalIdentifier.replacingOccurrences(of: "-", with: "_"),
                language.minimalIdentifier.replacingOccurrences(of: "_", with: "-")
            ]
            guard let bundle = candidateNames.firstNonNil({ name -> Bundle? in
                self.url(forResource: name, withExtension: "lproj").flatMap { Bundle(url: $0) }
            }) else {
                continue
            }
            if let title = bundle.localizedString(forKey: key, tables: tables) {
                return title
            }
        }
        // if we didn't find anything, we look for loctable files.
        for language in localizations {
            for table in tables {
                guard let url = self.url(
                    forResource: table.stringValue,
                    withExtension: "loctable",
                    subdirectory: nil,
                    localization: language.minimalIdentifier
                ) else {
                    continue
                }
                // NOTE: obvious potential for optimization here! there really is no need to re-read this mapping every time!
                guard let dict = try? NSDictionary(contentsOf: url, error: ()),
                      let entries = dict[language.minimalIdentifier] as? [String: String] else {
                    continue
                }
                if let title = entries[key] {
                    return title
                } else {
                    continue
                }
            }
        }
        // NOTE: we could add a fallback lookup here:
        // ```
        // if tables.contains(.default), let title = self.localizedString(forKey: key, tables: [.default]) {
        //     return title
        // }
        // ```
        // but for now we don't, in order to match the apparent behaviour of apple's implementation.
        return nil
    }
}
