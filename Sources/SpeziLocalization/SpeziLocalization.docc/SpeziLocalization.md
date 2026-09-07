# ``SpeziLocalization``

Work with localized resources.


## Overview

The SpeziLocalization target implements localization-related facilities, for working with localized string and file resources.

It defines extensions on `Bundle` and `LocalizedStringResource` to enable applications to work with multiple/dynamic localizations at runtime, and implements a `LocalizedStringResource`-inspired ``LocalizedFileResource`` type for working with file-based localization.

### Looking Up Strings Across Multiple Tables

Foundation's `Bundle.localizedString(forKey:value:table:)` only ever consults a single `.strings` table.
``Foundation/Bundle/localizedString(forKey:tables:)`` searches several tables in order and returns the first match, which allows a package to look up a key in its own table first,
and to fall back to the app's `Localizable.strings` (``Foundation/Bundle/LocalizationLookupTable/default``) if the app wants to override a string.
The function returns `nil` if none of the tables contain the key, rather than the key itself:

```swift
let greeting = Bundle.main.localizedString(
    forKey: "GREETING",
    tables: [.custom("Onboarding"), .default]
) ?? "GREETING"
```

``Foundation/Bundle/localizedString(forKey:tables:localizations:)`` additionally takes the languages to look up, in order of preference, instead of using the user's current language.
It performs more extensive fallback lookups than Foundation's `localizedString(forKey:value:table:localizations:)`: if you ask for `en-GB` and the bundle only provides a value for `en`, the `en` value is returned.

```swift
let greeting = Bundle.main.localizedString(
    forKey: "GREETING",
    tables: [.custom("Onboarding"), .default],
    localizations: [Locale.Language(identifier: "en-GB")]
)
```

The ranking underlying these lookups is available separately as ``Foundation/Bundle/preferredLocalizations(from:limitToPreferences:)``.
By default, it returns only those of the bundle's localizations that are related to the preferences (e.g. `[en-GB, en]` for a preference of `en-GB`);
pass `limitToPreferences: false` to get *all* of the bundle's localizations, sorted by preference, e.g. to populate a language picker.

### Localized File Resources

Foundation's `.lproj` mechanism localizes files inside a bundle, but not files that are downloaded at runtime or stored in a cloud bucket.
SpeziLocalization instead localizes files through a naming convention: the localized variants of `Welcome.md` are called `Welcome+en-US.md`, `Welcome+de-DE.md`, etc.,
i.e., the unlocalized name followed by a `+` and a ``LocalizationKey`` (language and region).

A ``LocalizedFileResource`` combines the unlocalized file name with the locale for which the file should be resolved (by default, the user's current locale).
``LocalizedFileResolution/resolve(_:from:using:fallback:)`` then picks the best match from a collection of candidate `URL`s, wherever those come from:

```swift
let candidates = [
    URL(filePath: "/content/Welcome+en-US.md"),
    URL(filePath: "/content/Welcome+en-GB.md"),
    URL(filePath: "/content/Welcome+de-DE.md")
]

// Resolves using the device's current locale, e.g. to "Welcome+en-GB.md" on a device set to British English.
if let resolved = LocalizedFileResolution.resolve("Welcome.md", from: candidates) {
    let contents = try String(contentsOf: resolved.url, encoding: .utf8)
}

// A German speaker in Austria: there is no "de-AT" variant, so the default matching behaviour picks "Welcome+de-DE.md".
let resource = LocalizedFileResource("Welcome.md", locale: Locale(identifier: "de-AT"))
let resolved = LocalizedFileResolution.resolve(resource, from: candidates)
```

If no candidate matches the resource's locale exactly, the ``LocaleMatchingBehaviour`` decides which partial match is acceptable:
``LocaleMatchingBehaviour/preferLanguageMatch`` (the default) prefers a candidate with the same language but a different region over one with the same region but a different language,
``LocaleMatchingBehaviour/preferRegionMatch`` does the opposite, and ``LocaleMatchingBehaviour/requirePerfectMatch`` rejects partial matches altogether.
If the locale cannot be matched at all, the `fallback` localization (`en-US` by default) is tried, and finally an unlocalized file with the requested name, if exactly one exists among the candidates.
The returned ``LocalizedFileResource/Resolved`` value carries the matched `url` alongside the `localization` that was actually selected, so that the caller can tell whether it received a fallback.

To enumerate every localized variant of a file, e.g. to offer a language choice, use ``LocalizedFileResolution/selectCandidatesIgnoringLocalization(matching:from:)``;
``LocalizedFileResolution/parse(_:)`` splits a single `URL` into its unlocalized `URL` and ``LocalizationKey``.

`SpeziStudy` uses this mechanism to resolve the localized consent documents, articles, and questionnaires contained in a study bundle.

### Localization Keys and Dictionaries

A ``LocalizationKey`` identifies a language and region combination such as `en-US`. It can be created from a `Locale` or parsed from a string, and encodes as that string when used with `Codable`.
``LocalizationKey/score(against:using:)-(Locale.Language,_)`` implements the matching behaviour described above and is what ``LocalizedFileResolution`` uses under the hood.

``LocalizationsDictionary`` is a dictionary keyed by ``LocalizationKey`` that applies the same matching rules on lookup,
which makes it a convenient representation for localized values that are defined in code or decoded from JSON, e.g. the localized title of a study:

```swift
let titles: LocalizationsDictionary<String> = [
    .enUS: "Welcome",
    LocalizationKey(language: .init(identifier: "de"), region: .germany): "Willkommen"
]

// Looks up the best match, rather than requiring an exact key: an Austrian German locale resolves to the German entry.
let title = titles[LocalizationKey(language: .init(identifier: "de"), region: .austria)] // "Willkommen"
```

The subscript accepts an optional ``LocaleMatchingBehaviour`` and `fallback` key, mirroring the file resolution API.


## Topics

### Working with Localized Strings
- ``Foundation/LocalizedStringResource/localizedString(for:)``
- ``Foundation/Bundle/localizedString(forKey:tables:)``
- ``Foundation/Bundle/localizedString(forKey:tables:localizations:)``
- ``Foundation/Bundle/preferredLocalizations(from:limitToPreferences:)``
- ``Foundation/Bundle/LocalizationLookupTable``
- ``Foundation/LocalizedStringResource/BundleDescription/atURL(from:)``

### Working with Localized File Resources
- ``LocalizedFileResource``
- ``LocalizedFileResolution``

### Localization Keys
- ``LocalizationKey``
- ``LocalizationsDictionary``
- ``LocaleMatchingBehaviour``
- ``Foundation/Locale/Language/withRegion(_:)``
