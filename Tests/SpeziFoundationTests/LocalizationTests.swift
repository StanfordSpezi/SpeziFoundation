//
// This source file is part of the Stanford Spezi open-source project
//
// SPDX-FileCopyrightText: 2025 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import Foundation
@_spi(Testing) import SpeziFoundation
import Testing


@Suite
struct LocalizationTests {
    private let allSupportedLanguages: [Locale.Language] = [.en, .de, .es, .enGB, .esUS]
    
    
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
        #expect(bundle.preferredLocalizations(from: [.enGB]) == [.enGB, .en])
        #expect(bundle.preferredLocalizations(from: [.esUS]) == [.esUS, .es])
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
        #expect(bundle.localizedString(forKey: key, tables: [.default], localizations: [.enGB]) == nil)
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
