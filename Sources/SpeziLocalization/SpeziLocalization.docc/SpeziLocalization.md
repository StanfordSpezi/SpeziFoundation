# ``SpeziLocalization``

Work with localized resources.


## Overview

The SpeziLocalization target implements localization-related facilities, for working with localized string and file resources.

It defines extensions on `Bundle` and `LocalizedStringResource` to enable applications to work with multiple/dynamic localizations at runtime, and implements a `LocalizedStringResource`-inspired ``LocalizedFileResource`` type for working with file-based localization.

### Looking Up Strings Across Multiple Tables

`Bundle.localizedString(forKey:tables:)` searches a list of `.strings` tables in order, returning the first match. This is useful when you want to look up a key in a feature-specific table and fall back to the shared default table:

```swift
// Look up "greeting" first in "Onboarding.strings", then in "Localizable.strings".
let greeting = Bundle.main.localizedString(
    forKey: "greeting",
    tables: [.custom("Onboarding"), .default]
)
```

To perform the same lookup for a specific locale rather than the current one, use the three-parameter overload. It applies proper language-tag fallback (e.g. `en-GB` → `en`) before consulting the tables:

```swift
let frenchGreeting = Bundle.main.localizedString(
    forKey: "greeting",
    tables: [.custom("Onboarding"), .default],
    localizations: [Locale.Language(identifier: "fr-FR")]
)
```

### Resolving Localized File Resources

``LocalizedFileResource`` identifies a file by its unlocalized name and a target locale. Pass a collection of candidate `URL`s to ``LocalizedFileResolution`` to get back the best-matching URL:

```swift
// Suppose your bundle ships these localized variants of a markdown article:
let candidates = [
    URL(filePath: "/content/Welcome+en-US.md"),
    URL(filePath: "/content/Welcome+de-DE.md"),
    URL(filePath: "/content/Welcome+es-US.md"),
]

// Create a resource that targets the current locale.
let resource = LocalizedFileResource("Welcome.md")

// Resolve to the best-matching URL (e.g. "Welcome+en-US.md" for an en-US device).
if let resolved = LocalizedFileResolution.resolve(resource, from: candidates) {
    let url: URL = resolved.url
    // Use `url` to load the file contents.
}

// Override the locale explicitly — resolves to "Welcome+de-DE.md".
let germanResource = LocalizedFileResource("Welcome.md", locale: Locale(identifier: "de-DE"))
if let resolved = LocalizedFileResolution.resolve(germanResource, from: candidates) {
    let url: URL = resolved.url
}
```

### Querying a Bundle's Preferred Localizations

`Bundle.preferredLocalizations(from:limitToPreferences:)` ranks the languages supported by a bundle according to a set of user preferences, making it easy to iterate over localizations in preference order:

```swift
let userPreferences: [Locale.Language] = [
    Locale.Language(identifier: "fr-FR"),
    Locale.Language(identifier: "en-GB"),
]

// Returns only the languages from `userPreferences` that the bundle actually supports,
// sorted by preference.
let preferred = Bundle.main.preferredLocalizations(from: userPreferences)

// Pass `limitToPreferences: false` to get all bundle localizations sorted by preference.
let all = Bundle.main.preferredLocalizations(from: userPreferences, limitToPreferences: false)
```


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
- ``LocalizationKey``
- ``LocalizedFileResolution``
- ``LocaleMatchingBehaviour``
