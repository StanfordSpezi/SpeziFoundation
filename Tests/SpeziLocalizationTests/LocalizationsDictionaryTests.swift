//
// This source file is part of the Stanford Spezi open source project
//
// SPDX-FileCopyrightText: 2026 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import Foundation
@testable import SpeziLocalization
import Testing

struct LocalizedContent: Hashable, Codable {
    let title: String
    let body: String
}

@Suite
struct LocalizationsDictionaryTests {

    @Test
    func emptyInit() {
        let dict = LocalizationsDictionary<String>()
        #expect(dict.isEmpty)
    }

    @Test
    func dictionaryLiteral() {
        let dict = LocalizationsDictionary<String>([
            .enUS: "Hello World!",
            .deDE: "Hallo Welt!"
        ])
        #expect(dict.count == 2)
        #expect(dict[.enUS] == "Hello World!")
        #expect(dict[.deDE] == "Hallo Welt!")
    }

    @Test
    func subscriptByString() {
        var dict = LocalizationsDictionary<String>([:])
        dict[.enUS] = "Hello World!"
        #expect(dict[.enUS] == "Hello World!")
        dict[.enUS] = nil
        #expect(dict[.enUS] == nil)
        #expect(dict.isEmpty)
    }

    @Test
    func subscriptByLocalizationKey() {
        var dict = LocalizationsDictionary<String>()
        let key = LocalizationKey.enUS
        dict[key] = "Hello World!"
        #expect(dict[key] == "Hello World!")
    }

    @Test
    func perfectMatch() {
        let dict = LocalizationsDictionary<String>([
            .enUS: "Hello World!",
            .deDE: "Hallo Welt!"
        ])
        let result = dict.localizedString(for: .enUS)
        #expect(result == "Hello World!")
    }

    @Test
    func partialLanguageMatch() {
        let dict = LocalizationsDictionary<String>([
            .enUS: "Hello World!",
            .deDE: "Hallo Welt!"
        ])
        let result = dict.localizedString(for: Locale(identifier: "en-GB"), using: .preferLanguageMatch)
        #expect(result == "Hello World!")
    }

    @Test
    func noMatchReturnsFallback() {
        let dict = LocalizationsDictionary<String>([
            .enUS: "Hello World!",
            .deDE: "Hallo Welt!"
        ])
        let result = dict.localizedString(
            for: Locale(identifier: "ja-JP"),
            using: .requirePerfectMatch,
            fallback: .enUS
        )
        #expect(result == "Hello World!")
    }

    @Test
    func noMatchNoFallback() {
        let dict = LocalizationsDictionary<String>([
            .deDE: "Hallo Welt!"
        ])
        let result = dict.localizedString(
            for: Locale(identifier: "ja-JP"),
            using: .requirePerfectMatch,
            fallback: nil
        )
        #expect(result == nil)
    }

    @Test
    func fallbackKeyNotInDictionary() {
        let dict = LocalizationsDictionary<String>([
            .deDE: "Hallo Welt!"
        ])
        let result = dict.localizedString(
            for: .frFR,
            using: .requirePerfectMatch,
            fallback: .enUS
        )
        #expect(result == nil)
    }


    @Test
    func codableRoundTrip() throws {
        let original = LocalizationsDictionary<String>([
            .enUS: "Hello World!",
            .deDE: "Hallo Welt!",
            LocalizationKey("es-ES")!: "Hola Mundo!"
        ])
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(LocalizationsDictionary<String>.self, from: data)
        #expect(decoded == original)
    }

    @Test
    func decodesFromJSON() throws {
        let json = Data(#"{"en-US":"Hello World!","de-DE":"Hallo Welt!"}"#.utf8)
        let dict = try JSONDecoder().decode(LocalizationsDictionary<String>.self, from: json)
        #expect(dict["en-US"] == "Hello World!")
        #expect(dict["de-DE"] == "Hallo Welt!")
        #expect(dict.count == 2)
    }


    @Test
    func collectionConformance() {
        let dict = LocalizationsDictionary<String>([
            .enUS: "Hello World!",
            .deDE: "Hallo Welt!"
        ])
        #expect(dict.count == 2)
        #expect(!dict.isEmpty)

        var values = Set<String>()
        for (_, value) in dict {
            values.insert(value)
        }
        #expect(values == ["Hello World!", "Hallo Welt!"])
    }

    @Test
    func hashableEquality() {
        let dict1 = LocalizationsDictionary<String>([.enUS: "Hello World!", .deDE: "Hallo Welt!"])
        let dict2 = LocalizationsDictionary<String>([.enUS: "Hello World!", .deDE: "Hallo Welt!"])
        let dict3 = LocalizationsDictionary<String>([.enUS: "Hello World"])
        #expect(dict1 == dict2)
        #expect(dict1 != dict3)
        #expect(Set([dict1, dict2]).count == 1)
    }

    @Test
    func structuredValueCreation() {
        let dict = LocalizationsDictionary<LocalizedContent>([
            .enUS: LocalizedContent(title: "Welcome", body: "Hello there"),
            .deDE: LocalizedContent(title: "Willkommen", body: "Hallo")
        ])
        #expect(dict.count == 2)
        #expect(dict[.enUS] == LocalizedContent(title: "Welcome", body: "Hello there"))
    }

    @Test
    func structuredValueSubscript() {
        var dict = LocalizationsDictionary<LocalizedContent>()
        let content = LocalizedContent(title: "Welcome", body: "Hello there")
        dict[.enUS] = content
        #expect(dict[.enUS] == content)
    }

    @Test
    func structuredValueLocalizedValue() {
        let dict = LocalizationsDictionary<LocalizedContent>([
            .enUS: LocalizedContent(title: "Welcome", body: "Hello there"),
            .deDE: LocalizedContent(title: "Willkommen", body: "Hallo")
        ])
        let result = dict.localizedValue(for: .deDE)
        #expect(result == LocalizedContent(title: "Willkommen", body: "Hallo"))
    }

    @Test
    func structuredValueCodable() throws {
        let original = LocalizationsDictionary<LocalizedContent>([
            .enUS: LocalizedContent(title: "Welcome", body: "Hello there"),
            .deDE: LocalizedContent(title: "Willkommen", body: "Hallo")
        ])
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(LocalizationsDictionary<LocalizedContent>.self, from: data)
        #expect(decoded == original)
    }
}
