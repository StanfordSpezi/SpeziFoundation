//
// This source file is part of the Stanford Spezi open-source project
//
// SPDX-FileCopyrightText: 2025 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import Foundation
#if os(macOS) || targetEnvironment(macCatalyst)
import HealthKit
#endif
@_spi(Testing) @testable import SpeziLocalization
import Testing

// Suite is Skipped on Linux:
// localization methods are unavailable outside Apple platforms
#if canImport(Darwin)
@Suite
struct LocalizationTests {
    private let allSupportedLanguages: [Locale.Language] = [
        .en, .de, .es, .enGB, .esUS
    ]
    
    @Test
    @available(macOS 15.4, iOS 18.4, tvOS 18.4, watchOS 11.4, visionOS 2.4, *)
    func unsupportedLang() {
        let bundle = Bundle.module
        
        #expect(bundle.localizedString(forKey: "LOCALIZATION_LANG", value: nil, table: nil, localizations: [.en]) == "en")
        #expect(bundle.localizedStringForKeyFallback(key: "LOCALIZATION_LANG", tables: [.default], localizations: [.en]) == "en")
        #expect(bundle.localizedString(forKey: "LOCALIZATION_LANG", value: nil, table: nil, localizations: [.jp]) == "en")
        #expect(bundle.localizedStringForKeyFallback(key: "LOCALIZATION_LANG", tables: [.default], localizations: [.jp]) == "en")
    }
    
    
    @Test
    func preferredLocalizationsSimple() {
        let bundle = Bundle.module
        for lang in [Locale.Language.en, .de, .es] {
            #expect(bundle.preferredLocalizations(from: [lang]) == [lang])
        }
    }
    
    
    @Test
    func preferredLocalizationsSpecializations() {
        let bundle = Bundle.module
        let idents = { ($0 as [Locale.Language]).map(\.minimalIdentifier) }
        #expect(idents(bundle.preferredLocalizations(from: [.enGB])) == idents([.enGB, .en]))
        #expect(idents(bundle.preferredLocalizations(from: [.esUS])) == idents([.esUS, .es]))
        #expect(idents(bundle.preferredLocalizations(from: [.enGB, .en])) == idents([.enGB, .en]))
        #expect(idents(bundle.preferredLocalizations(from: [.en, .enGB])) == idents([.en]))
        #expect(idents(bundle.preferredLocalizations(from: [.fr], limitToPreferences: false)).starts(with: ["fr", "en", "en-GB", "de"]))
        #expect(idents(bundle.preferredLocalizations(from: [.fr, .es], limitToPreferences: false)).starts(with: ["fr", "es", "es-US", "en", "en-GB"]))
        #expect(idents(bundle.preferredLocalizations(from: [.de, .enGB], limitToPreferences: false)).starts(with: ["de", "en-GB", "en"]))
        #expect(idents(bundle.preferredLocalizations(from: [.de], limitToPreferences: false)).starts(with: ["de", "en", "en-GB"]))
    }
    
    
    @Test
    @available(macOS 15.4, iOS 18.4, tvOS 18.4, watchOS 11.4, visionOS 2.4, *)
    func bundleLocalizationUtils0() throws {
        let bundle = Bundle.module
        let key = "LOCALIZATION_LANG"
        for lang in allSupportedLanguages {
            let value1 = bundle.localizedString(forKey: key, value: "NOT_FOUND", table: nil, localizations: [lang])
            let value2 = bundle.localizedStringForKeyFallback(key: key, tables: [], localizations: [lang])
            #expect(value1 == value2, "lang: \(lang.minimalIdentifier)")
        }
    }
    
    
    @Test
    @available(macOS 15.4, iOS 18.4, tvOS 18.4, watchOS 11.4, visionOS 2.4, *)
    func bundleLocalizationUtils1() throws {
        let bundle = Bundle.module
        let key = "LOCALIZATION_LANG_2"
        
        #expect(bundle.localizedString(forKey: key, value: "nil", table: nil, localizations: [.enGB]) == "nil")
        #expect(bundle.localizedString(forKey: key, tables: [.default], localizations: [.enGB]) == "en")
        #expect(bundle.localizedStringForKeyFallback(key: key, tables: [.default], localizations: [.enGB]) == "en")
        
        #expect(bundle.localizedString(forKey: key, value: "nil", table: nil, localizations: [.enGB, .en]) == "nil")
        #expect(bundle.localizedString(forKey: key, tables: [.default], localizations: [.enGB, .en]) == "en")
        #expect(bundle.localizedStringForKeyFallback(key: key, tables: [.default], localizations: [.enGB, .en]) == "en")
        
        #expect(bundle.localizedString(forKey: key, value: "nil", table: nil, localizations: [.en, .enGB]) == "en")
        #expect(bundle.localizedString(forKey: key, tables: [.default], localizations: [.en, .enGB]) == "en")
        #expect(bundle.localizedStringForKeyFallback(key: key, tables: [.default], localizations: [.en, .enGB]) == "en")
        
        #expect(bundle.localizedString(forKey: key, value: "nil", table: nil, localizations: [.de, .en]) == "de")
        #expect(bundle.localizedString(forKey: key, tables: [.default], localizations: [.de, .en]) == "de")
        #expect(bundle.localizedStringForKeyFallback(key: key, tables: [.default], localizations: [.de, .en]) == "de")
        
        #expect(bundle.localizedStringForKeyFallback(key: key, tables: [.default], localizations: [.enGB]) == "en")
        #expect(bundle.localizedStringForKeyFallback(key: key, tables: [.default], localizations: [.enGB, .en]) == "en")
        #expect(bundle.localizedStringForKeyFallback(key: key, tables: [.default], localizations: [.de, .en]) == "de")
    }
    
    
    @Test
    @available(macOS 14.0, macCatalyst 17.0, *)
    func bundleLocalizationUtils2() throws {
        #if os(macOS) || targetEnvironment(macCatalyst)
        let bundle = Bundle(for: HKHealthStore.self)
        let key1 = "STEPS"
        
        #expect(bundle.localizedString(forKey: key1, tables: [.custom("Localizable-DataTypes")], localizations: [.de]) == "Schritte")
        #expect(bundle.localizedStringForKeyFallback(key: key1, tables: [.custom("Localizable-DataTypes")], localizations: [.de]) == "Schritte")
        
        #expect(bundle.localizedString(forKey: key1, tables: [.custom("Localizable-DataTypes")], localizations: [.en]) == "Steps")
        #expect(bundle.localizedStringForKeyFallback(key: key1, tables: [.custom("Localizable-DataTypes")], localizations: [.en]) == "Steps")
        
        #expect(bundle.localizedString(forKey: key1, tables: [.custom("Localizable-DataTypes")], localizations: [.en, .de]) == "Steps")
        #expect(bundle.localizedStringForKeyFallback(key: key1, tables: [.custom("Localizable-DataTypes")], localizations: [.en, .de]) == "Steps")
        
        #expect(bundle.localizedString(forKey: key1, tables: [.custom("Localizable-DataTypes")], localizations: [.de, .en]) == "Schritte")
        #expect(bundle.localizedStringForKeyFallback(key: key1, tables: [.custom("Localizable-DataTypes")], localizations: [.de, .en]) == "Schritte")
        #endif
    }
    
    
    @Test
    func localizedStringResourceUtil() {
        let resource = LocalizedStringResource(
            "HELLO_WORLD",
            defaultValue: "HELLO_WORLD",
            bundle: .atURL(from: .module)
        )
        #expect(resource.localizedString(for: .init(identifier: "en_US")) == "Hello, World!")
        #expect(resource.localizedString(for: .init(identifier: "de_DE")) == "Hallo, Welt!")
    }
    
    
    @Test
    func localizationKeys() throws {
        #expect(Locale(identifier: "en-UK") == Locale(identifier: "en-GB"))
        #expect(Locale(identifier: "en-UK").identifier == "en-GB")
        #expect(LocalizationKey(locale: .init(identifier: "de_DE"))?.description == "de-DE")
        #expect(LocalizationKey(locale: .init(identifier: "de-DE"))?.description == "de-DE")
        #expect(LocalizationKey(locale: .init(identifier: "en-US"))?.description == "en-US")
        #expect(LocalizationKey(locale: .init(identifier: "en-UK"))?.description == "en-GB")
        #expect(LocalizationKey(locale: .init(identifier: "en-GB"))?.description == "en-GB")
        #expect(LocalizationKey(locale: .init(identifier: "en-DE"))?.description == "en-DE")
        #expect(LocalizationKey(locale: .init(identifier: "es_DE"))?.description == "es-DE")
    }
    
    @Test
    func lozalisationKeyParsing() {
        #expect(Locale(identifier: "en-UK").language == .enGB)
        #expect(Locale(identifier: "en-UK").region == .unitedKingdom)
        #expect(Locale(identifier: "en-UK").region?.isISORegion == true)
        #expect(LocalizationKey("en-UK") == LocalizationKey(language: .en, region: .unitedKingdom))
        #expect(LocalizationKey("en-GB") == LocalizationKey(language: .en, region: .unitedKingdom))
    }
}


extension Locale.Language {
    // swiftlint:disable identifier_name
    fileprivate static let en = Self(identifier: "en")
    fileprivate static let de = Self(identifier: "de")
    fileprivate static let fr = Self(identifier: "fr")
    fileprivate static let es = Self(identifier: "es")
    fileprivate static let jp = Self(identifier: "jp")
    fileprivate static let enGB = Self(identifier: "en-GB")
    fileprivate static let esUS = Self(identifier: "es-US")
    // swiftlint:enable identifier_name
}

#endif
