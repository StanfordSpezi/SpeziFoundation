//
// This source file is part of the Stanford Spezi open source project
//
// SPDX-FileCopyrightText: 2025 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

public import Foundation


/// Locale information used to localize files, and to resolve them.
///
/// A Localization Key consists of a ``language`` and a ``region``.
///
/// ## Topics
///
/// ### Initializers
/// - ``init(language:region:)``
/// - ``init(locale:)``
/// - ``init(parsingFilename:)``
/// - ``init(_:)``
///
/// ### Properties
/// - ``language``
/// - ``region``
/// - ``description``
///
/// ### Instance Methods
/// - ``score(against:using:)``
public struct LocalizationKey: Hashable, Sendable {
    /// The `en-US` localization key
    public static let enUS = Self(language: .init(identifier: "en"), region: .unitedStates)
    
    /// The localization key's language
    public let language: Locale.Language
    /// The localization key's region
    public let region: Locale.Region
    
    /// Creates a new Localization Key
    public init(language: Locale.Language, region: Locale.Region) {
        self.language = language
        self.region = region
    }
    
    /// Creates a new Localization Key, from a `Locale`
    ///
    /// This initializer fails if the locale's region is nil. This will happen if you use e.g. `Locale(identifier: "fr")` instead of `Locale(identifier: "fr-FR")`.
    public init?(locale: Locale) {
        guard let region = locale.region else {
            // this should be exceedingly unlikely to happen: https://stackoverflow.com/a/74563008
            return nil
        }
        self.init(language: locale.language, region: region)
    }
    
    /// Creates a new Localization Key by extracting a localization suffix from a filename
    public init?(parsingFilename filename: String) {
        guard let components = filename.parseLocalizationComponents(),
              let localization = LocalizationKey(components.rawLocalization) else {
            return nil
        }
        self = localization
    }
    
    /// Match a Localization Key against a Locale.
    ///
    /// Determines how well the LocalizationKey matches the Locale, on a scale from 0 to 1.
    public func score(against locale: Locale, using localeMatchingBehaviour: LocaleMatchingBehaviour = .default) -> Double {
        let languageMatches = if let selfCode = self.language.languageCode, let otherCode = locale.language.languageCode {
            selfCode.identifier == otherCode.identifier
        } else {
            self.language.minimalIdentifier == locale.language.minimalIdentifier
        }
        // IDEA: maybe also allow matching against parent regions?
        // (eg: if the user is in Canada, but the region in the key is just north america in general, that should still match...)
        let regionMatches = locale.region?.identifier == self.region.identifier
        guard !(languageMatches && regionMatches) else { // perfect match
            return 1
        }
        switch localeMatchingBehaviour {
        case .requirePerfectMatch:
            return 0 // we've already checked for a perfect match above...
        case .preferLanguageMatch:
            return languageMatches ? 0.8 : regionMatches ? 0.75 : 0
        case .preferRegionMatch:
            return regionMatches ? 0.8 : languageMatches ? 0.75 : 0
        case .custom(let imp):
            guard let key = LocalizationKey(locale: locale) else {
                return 0
            }
            return imp(self, key)
        }
    }
}


extension LocalizationKey: LosslessStringConvertible {
    public var description: String {
        language.minimalIdentifier + "-" + region.identifier
    }
    
    /// Attempts to create a Localization Key, by parsing the input.
    public init?(_ description: String) {
        let components = description.split(separator: "-")
        guard components.count == 2 else {
            return nil
        }
        let languageIdentifier = components[0]
        let regionIdentifier = components[1]
        guard let language = Locale.Language.systemLanguages.first(where: { $0.minimalIdentifier == languageIdentifier }),
              let region = Locale.Region.isoRegions.first(where: { $0.identifier == regionIdentifier }) else {
            return nil
        }
        self.init(language: language, region: region)
    }
}
