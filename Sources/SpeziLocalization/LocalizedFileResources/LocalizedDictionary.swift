//
// This source file is part of the Stanford Spezi open source project
//
// SPDX-FileCopyrightText: 2026 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

public import Foundation


/// A dictionary of localized values keyed by locale.
///
/// Use `LocalizedDictionary` to store values for multiple locales in a single value,
/// and resolve the best match for a given `Locale` using `LocaleMatchingBehaviour` scoring.
///
/// The type parameter `Value` determines what is stored per locale. For simple string translations,
/// use `LocalizedDictionary<String>`:
///
/// ```swift
/// let translations = LocalizedDictionary<String>([
///     .enUS: "Hello",
///     .deDE: "Hallo",
///     .enES: "Hola"
/// ])
/// let greeting = translations.localizedString(for: .deDE)
/// // greeting == "Hallo"
/// ```
///
/// You can also store structured content per locale:
///
/// ```swift
/// struct Article: Hashable, Codable {
///     let title: String
///     let content: String
/// }
/// let articles = LocalizedDictionary<Article>([
///     .enUS: Article(title: "Welcome", content: "Hello there"),
///     .deDE Article(title: "Willkommen", content: "Hallo")
/// ])
/// let article = articles.localizedValue(for: .deDE)
/// // article == Article(title: "Willkommen", content: "Hallo")
/// ```
///
/// ## Topics
///
/// ### Initializers
/// - ``init()``
/// - ``init(_:)``
///
/// ### Subscripts
/// - ``subscript(_:)
/// - ``subscript(_:)
///
/// ### Resolving Values
/// - ``localizedValue(for:using:fallback:)``
/// - ``localizedString(for:using:fallback:)``
public struct LocalizedDictionary<Value> {
    private var storage: [LocalizationKey: Value]

    /// Creates an empty localizations dictionary.
    public init() {
        self.storage = [:]
    }

    /// Creates a localizations dictionary from the given entries.
    public init(_ entries: [LocalizationKey: Value]) {
        self.storage = entries
    }

    /// Resolves the best value for the given locale.
    ///
    /// Iterates all entries in the dictionary, scores each ``LocalizationKey`` against the target `locale`
    /// using ``LocalizationKey/score(against:using:)-(Locale,_)``, and returns the entry with the highest score
    /// (provided it exceeds `0`). If no match is found and a `fallback` key is specified, the fallback entry is returned.
    ///
    /// - Parameters:
    ///   - locale: The locale to resolve a value for. Defaults to `/Locale/autoupdatingCurrent`.
    ///   - localeMatchingBehaviour: The matching behaviour to use. Defaults to ``LocaleMatchingBehaviour/default``.
    ///   - fallback: An optional fallback ``LocalizationKey`` to use if no match is found. Defaults to ``LocalizationKey/enUS``.
    /// - Returns: The best matching value, or `nil` if no match and no fallback exists.
    public func localizedValue(
        for locale: Locale = .autoupdatingCurrent,
        using localeMatchingBehaviour: LocaleMatchingBehaviour = .default,
        fallback: LocalizationKey? = .enUS
    ) -> Value? {
        var bestScore: Double = 0
        var bestValue: Value?
        for (key, value) in storage {
            let score = key.score(against: locale, using: localeMatchingBehaviour)
            if score > bestScore {
                bestScore = score
                bestValue = value
            }
        }
        if let bestValue {
            return bestValue
        }
        if let fallback {
            return storage[fallback]
        }
        return nil
    }

    /// Access a value by its ``LocalizationKey``.
    public subscript(_ key: LocalizationKey) -> Value? {
        get { storage[key] }
        set { storage[key] = newValue }
    }

    /// Access a value by a string identifier (e.g. `"en-US"`).
    ///
    /// Returns `nil` if the string cannot be parsed into a ``LocalizationKey``.
    public subscript(_ key: String) -> Value? {
        get {
            guard let locKey = LocalizationKey(key) else {
                return nil
            }
            return storage[locKey]
        }
        set {
            guard let locKey = LocalizationKey(key) else {
                return
            }
            storage[locKey] = newValue
        }
    }
}

extension LocalizedDictionary where Value == String {
    /// Resolves the best translation for the given locale.
    ///
    /// This is a convenience method equivalent to ``localizedValue(for:using:fallback:)`` for string dictionaries.
    ///
    /// - Parameters:
    ///   - locale: The locale to resolve a translation for. Defaults to `Locale/autoupdatingCurrent`.
    ///   - localeMatchingBehaviour: The matching behaviour to use. Defaults to ``LocaleMatchingBehaviour/default``.
    ///   - fallback: An optional fallback ``LocalizationKey`` to use if no match is found. Defaults to ``LocalizationKey/enUS``.
    /// - Returns: The best matching translation, or `nil` if no match and no fallback exists.
    public func localizedString(
        for locale: Locale = .autoupdatingCurrent,
        using localeMatchingBehaviour: LocaleMatchingBehaviour = .default,
        fallback: LocalizationKey? = .enUS
    ) -> String? {
        localizedValue(for: locale, using: localeMatchingBehaviour, fallback: fallback)
    }
}

extension LocalizedDictionary: Equatable where Value: Equatable {}
extension LocalizedDictionary: Hashable where Value: Hashable {}
extension LocalizedDictionary: Sendable where Value: Sendable {}

extension LocalizedDictionary: Encodable where Value: Encodable {
    public func encode(to encoder: any Encoder) throws {
        try storage.encode(to: encoder)
    }
}

extension LocalizedDictionary: Decodable where Value: Decodable {
    public init(from decoder: any Decoder) throws {
        self.storage = try [LocalizationKey: Value](from: decoder)
    }
}

extension LocalizedDictionary: Collection {
    public typealias Index = Dictionary<LocalizationKey, Value>.Index
    public typealias Element = Dictionary<LocalizationKey, Value>.Element

    public var startIndex: Index {
        storage.startIndex
    }

    public var endIndex: Index {
        storage.endIndex
    }

    public func index(after index: Index) -> Index {
        storage.index(after: index)
    }

    public subscript(position: Index) -> Element {
        storage[position]
    }
}
