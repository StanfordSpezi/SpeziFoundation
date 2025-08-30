//
// This source file is part of the Stanford Spezi open source project
//
// SPDX-FileCopyrightText: 2025 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

private import Algorithms
public import Foundation
private import OSLog


/// Namespace for Localized File Resolution operations
public enum LocalizedFileResolution {
    private static let logger = Logger(subsystem: "edu.stanford.SpeziLocalization", category: "FileResolution")
}

extension LocalizedFileResolution {
    private struct ScoredCandidate: Hashable, Comparable, Sendable {
        let fileResource: LocalizedFileResource.Resolved
        let score: Double
        
        static func < (lhs: Self, rhs: Self) -> Bool {
            lhs.score < rhs.score
        }
    }
    
    /// Resolves a localized resource from a set of inputs, based on an unlocalizdd filename and a target locale.
    public static func resolve(
        _ resource: LocalizedFileResource,
//        named unlocalizedFilename: String,
        from candidates: some Collection<URL>,
//        locale: Locale,
        using localeMatchingBehaviour: LocaleMatchingBehaviour = .preferLanguageMatch,
        fallback fallbackLocale: LocalizationKey? = .enUS
    ) -> LocalizedFileResource.Resolved? {
        let candidates: [ScoredCandidate] = candidates
            .lazy
            .compactMap { LocalizedFileResource.Resolved(resource: resource, url: $0) }
            .filter { $0.url.matches(unlocalizedFilename: resource.name) }
            .map { ScoredCandidate(fileResource: $0, score: $0.localization.score(against: resource.locale, using: localeMatchingBehaviour)) }
            .sorted(by: >)
        guard let candidate = candidates.first, candidate.score > 0.5 else {
            Self.logger.error("Unable to find url for \(resource.name) and locale \(resource.locale) (key: \(LocalizationKey(locale: resource.locale))).")
            if candidates.isEmpty {
                Self.logger.error("No candidates")
            } else {
                Self.logger.error("Candidates:")
                for candidate in candidates {
                    Self.logger.error("- \(candidate.score) @ \(candidate.fileResource.fullFilenameIncludingLocalization)")
                }
            }
            if let fallbackLocale, let fallback = candidates.first(where: { $0.fileResource.localization == fallbackLocale }) {
                Self.logger.warning("Falling back to \(fallbackLocale) locale.")
                return fallback.fileResource
            }
            return nil
        }
        if let equallyBestRanked = candidates.lazy.chunked(by: { $0.score == $1.score }).first, !equallyBestRanked.isEmpty { // will always be true.
            guard equallyBestRanked.count == 1 else {
                var errorMsg = "Error: Found multiple candidates for \(resource.name) @ \(resource.locale), all of which are equally ranked! Returning nil."
                for candidate in candidates {
                    errorMsg.append("\n- \(candidate.score) @ \(candidate.fileResource.fullFilenameIncludingLocalization)")
                }
                Self.logger.error("\(errorMsg)")
                return nil
            }
        }
        return candidate.fileResource
    }
}


extension URL {
    fileprivate func matches(unlocalizedFilename: String) -> Bool {
        self.strippingLocalizationSuffix().pathComponents.ends(with: unlocalizedFilename.split(separator: "/"), by: ==)
    }
    
    /// Returns a copy of the URL, with a potential loalization suffix removed.
    func strippingLocalizationSuffix() -> URL {
        guard let components = self.lastPathComponent.parseLocalizationComponents() else {
            return self
        }
        var newUrl = self.deletingLastPathComponent().appending(component: components.baseName)
        if let fileExtension = components.fileExtension {
            newUrl.appendPathExtension(fileExtension)
        }
        return newUrl
    }
}


extension StringProtocol {
    func parseLocalizationComponents() -> (baseName: String, fileExtension: String?, rawLocalization: String)? {
        // swiftlint:disable:previous large_tuple
        guard let separatorIdx = self.lastIndex(of: "+") else {
            return nil
        }
        var filename = self[...]
        let baseName = String(filename[..<separatorIdx])
        filename.removeFirst(baseName.count + 1)
        guard let fileExtIdx = filename.firstIndex(of: ".") else {
            return (baseName, nil, String(filename))
        }
        let rawLocalization = String(filename[..<fileExtIdx])
        filename.removeFirst(rawLocalization.count + 1)
        let fileExtension = String(filename)
        return (baseName, fileExtension, rawLocalization)
    }
}

extension BidirectionalCollection {
    /// Determines whether the collection ends with the elements of another collection.
    public func ends(
        with possibleSuffix: some BidirectionalCollection<Element>
    ) -> Bool where Element: Equatable {
        ends(with: possibleSuffix, by: ==)
    }
    
    /// Determines whether the collection ends with the elements of another collection.
    public func ends<PossibleSuffix: BidirectionalCollection, E: Error>(
        with possibleSuffix: PossibleSuffix,
        by areEquivalent: (Element, PossibleSuffix.Element) throws(E) -> Bool
    ) throws(E) -> Bool {
        guard self.count >= possibleSuffix.count else {
            return false
        }
        for (elem1, elem2) in zip(self.reversed(), possibleSuffix.reversed()) {
            guard try areEquivalent(elem1, elem2) else {
                return false
            }
        }
        return true
    }
}
