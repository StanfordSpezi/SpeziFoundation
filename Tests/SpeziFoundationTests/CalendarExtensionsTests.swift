// This source file is part of the Stanford Spezi open-source project
//
// SPDX-FileCopyrightText: 2024 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import Foundation
import RuntimeAssertions
@testable import SpeziFoundation
import Testing

private struct RegionConfiguration: Hashable {
    let locale: Locale // swiftlint:disable:this type_contents_order
    let timeZone: TimeZone // swiftlint:disable:this type_contents_order
    
    static let losAngeles = Self(
        locale: .init(identifier: "en_US"),
        timeZone: .init(identifier: "America/Los_Angeles")! // swiftlint:disable:this force_unwrapping
    )
    
    static let berlin = Self(
        locale: .init(identifier: "en_DE"),
        timeZone: .init(identifier: "Europe/Berlin")! // swiftlint:disable:this force_unwrapping
    )
    
    static let current = Self(locale: .current, timeZone: .current)
    
    /// Returns a copy of the calendar, with the locale and time zone set based on the region.
    func applying(to calendar: Calendar) -> Calendar {
        var cal = calendar
        cal.locale = locale
        cal.timeZone = timeZone
        return cal
    }
}


/// Tests for the `Calendar` extensions.
/// - Note: most tests, by  default simply run in the context of the current system locale and time zone.
///     For some tests, however, this is manually overwritten (mainly to deal with locale-dependent differences
///     such as DST, first weekday, etc).
@Suite("Calendar Extensions Tests")
final class CalendarExtensionsTests { // swiftlint:disable:this type_body_length
    private var cal = Calendar.current
    
    private func makeDate(year: Int, month: Int, day: Int, hour: Int, minute: Int = 0, second: Int = 0) throws -> Date {
        let components = DateComponents(year: year, month: month, day: day, hour: hour, minute: minute, second: second)
        return try #require(cal.date(from: components))
    }
    
    
    /// Runs a block in the calendar-context of a region
    private func withRegion(_ region: RegionConfiguration, _ block: () throws -> Void) rethrows {
        let prevCal = cal
        cal = region.applying(to: cal)
        defer {
            cal = prevCal
        }
        try block()
    }
    
    /// Runs a block multiple times, in different calendar-contexts, once for each specified region.
    private func withRegions(_ regions: RegionConfiguration..., block: () throws -> Void) rethrows {
        for region in Set(regions) {
            try withRegion(region, block)
        }
    }
    
    
    @Test
    func testRangeComputations() throws {
        try withRegions(.current, .losAngeles, .berlin) {
            try #require(
                try cal.rangeOfHour(for: makeDate(year: 2024, month: 12, day: 27, hour: 14, minute: 12)) ==
                (makeDate(year: 2024, month: 12, day: 27, hour: 14))..<(makeDate(year: 2024, month: 12, day: 27, hour: 15))
            )
            try #require(
                try cal.rangeOfDay(for: makeDate(year: 2024, month: 12, day: 27, hour: 14, minute: 12)) ==
                (makeDate(year: 2024, month: 12, day: 27, hour: 00))..<(makeDate(year: 2024, month: 12, day: 28, hour: 0))
            )
        }
        
        try withRegion(.losAngeles) {
            try #require(
                try cal.rangeOfWeek(for: makeDate(year: 2024, month: 12, day: 27, hour: 14, minute: 12)) ==
                (makeDate(year: 2024, month: 12, day: 22, hour: 00))..<(makeDate(year: 2024, month: 12, day: 29, hour: 0))
            )
            try #require(
                try cal.rangeOfWeek(for: makeDate(year: 2024, month: 12, day: 31, hour: 14, minute: 12)) ==
                (makeDate(year: 2024, month: 12, day: 29, hour: 00))..<(makeDate(year: 2025, month: 01, day: 05, hour: 0))
            )
        }
        
        try withRegion(.berlin) {
            try #require(
                try cal.rangeOfWeek(for: makeDate(year: 2024, month: 12, day: 27, hour: 14, minute: 12)) ==
                (makeDate(year: 2024, month: 12, day: 23, hour: 00))..<(makeDate(year: 2024, month: 12, day: 30, hour: 0))
            )
            try #require(
                try cal.rangeOfWeek(for: makeDate(year: 2024, month: 12, day: 31, hour: 14, minute: 12)) ==
                (makeDate(year: 2024, month: 12, day: 30, hour: 00))..<(makeDate(year: 2025, month: 01, day: 06, hour: 0))
            )
        }
        
        try withRegions(.current, .losAngeles, .berlin) {
            try #require(
                try cal.rangeOfMonth(for: makeDate(year: 2024, month: 12, day: 31, hour: 14, minute: 12)) ==
                (makeDate(year: 2024, month: 12, day: 01, hour: 00))..<(makeDate(year: 2025, month: 01, day: 01, hour: 0))
            )
            try #require(
                try cal.rangeOfYear(for: makeDate(year: 2024, month: 12, day: 31, hour: 14, minute: 12)) ==
                (makeDate(year: 2024, month: 01, day: 01, hour: 00))..<(makeDate(year: 2025, month: 01, day: 01, hour: 0))
            )
            try #require(
                try cal.rangeOfMonth(for: makeDate(year: 2024, month: 02, day: 29, hour: 14, minute: 12)) ==
                (makeDate(year: 2024, month: 02, day: 01, hour: 0))..<(makeDate(year: 2024, month: 03, day: 01, hour: 0))
            )
        }
    }
    
    @Test
    func testDistinctDistances() throws { // swiftlint:disable:this function_body_length
        func imp(
            start: Date,
            end: Date,
            fn: (Date, Date) -> Int, // swiftlint:disable:this identifier_name
            expected: Int,
            sourceLocation: SourceLocation = #_sourceLocation
        ) {
            let distance = fn(start, end)
            #expect(distance == expected, sourceLocation: sourceLocation)
            #expect(fn(start, end) == fn(end, start), sourceLocation: sourceLocation)
        }
        
        func imp(
            start: (year: Int, month: Int, day: Int, hour: Int, minute: Int), // swiftlint:disable:this large_tuple
            end: (year: Int, month: Int, day: Int, hour: Int, minute: Int), // swiftlint:disable:this large_tuple
            fn: (Date, Date) -> Int, // swiftlint:disable:this identifier_name
            expected: Int,
            sourceLocation: SourceLocation = #_sourceLocation
        ) throws {
            imp(
                start: try makeDate(year: start.year, month: start.month, day: start.day, hour: start.hour, minute: start.minute),
                end: try makeDate(year: end.year, month: end.month, day: end.day, hour: end.hour, minute: end.minute),
                fn: fn,
                expected: expected,
                sourceLocation: sourceLocation,
            )
        }
        
        try withRegions(.current, .losAngeles, .berlin) { // swiftlint:disable:this closure_body_length
            try imp(
                start: (year: 2021, month: 02, day: 02, hour: 07, minute: 20),
                end: (year: 2021, month: 02, day: 02, hour: 08, minute: 05),
                fn: cal.countDistinctHours(from:to:),
                expected: 2
            )
            try imp(
                start: (year: 2021, month: 02, day: 02, hour: 07, minute: 20),
                end: (year: 2021, month: 02, day: 02, hour: 07, minute: 21),
                fn: cal.countDistinctHours(from:to:),
                expected: 1
            )
            try imp(
                start: (year: 2021, month: 02, day: 02, hour: 07, minute: 20),
                end: (year: 2021, month: 02, day: 02, hour: 07, minute: 21),
                fn: cal.countDistinctHours(from:to:),
                expected: 1
            )
            
            for transition in cal.timeZone.nextDSTTransitions(maxCount: 10) {
                let range = cal.rangeOfDay(for: transition.date)
                #expect(
                    cal.countDistinctHours(from: range.lowerBound, to: range.upperBound.addingTimeInterval(-1)) ==
                    24 - Int(transition.change / 3600)
                )
            }
            
            try imp(
                start: (year: 2021, month: 02, day: 02, hour: 09, minute: 00),
                end: (year: 2021, month: 02, day: 03, hour: 07, minute: 00),
                fn: cal.countDistinctDays(from:to:),
                expected: 2
            )
            try imp(
                start: (year: 2021, month: 02, day: 28, hour: 09, minute: 00),
                end: (year: 2021, month: 03, day: 01, hour: 07, minute: 00),
                fn: cal.countDistinctDays(from:to:),
                expected: 2
            )
            try imp(
                start: (year: 2024, month: 02, day: 28, hour: 09, minute: 00),
                end: (year: 2024, month: 03, day: 01, hour: 07, minute: 00),
                fn: cal.countDistinctDays(from:to:),
                expected: 3 // leap year
            )
            
            let now = Date()
            imp(
                start: now,
                end: now,
                fn: cal.countDistinctDays(from:to:),
                expected: 1
            )
            
            imp(
                start: cal.startOfDay(for: now),
                end: cal.startOfNextDay(for: now),
                fn: cal.countDistinctDays(from:to:),
                expected: 2
            )
            try imp(
                start: (year: 2021, month: 02, day: 07, hour: 07, minute: 00),
                end: (year: 2021, month: 02, day: 07, hour: 07, minute: 15),
                fn: cal.countDistinctWeeks(from:to:),
                expected: 1
            )
        }
        
        try withRegion(.losAngeles) {
            try imp(
                start: (year: 2021, month: 02, day: 07, hour: 07, minute: 00),
                end: (year: 2021, month: 02, day: 08, hour: 07, minute: 15),
                fn: cal.countDistinctWeeks(from:to:),
                expected: 1
            )
            try imp(
                start: (year: 2024, month: 12, day: 29, hour: 07, minute: 00),
                end: (year: 2025, month: 01, day: 02, hour: 07, minute: 15),
                fn: cal.countDistinctWeeks(from:to:),
                expected: 1
            )
            try imp(
                start: (year: 2021, month: 02, day: 06, hour: 07, minute: 00),
                end: (year: 2021, month: 02, day: 07, hour: 07, minute: 15),
                fn: cal.countDistinctWeeks(from:to:),
                expected: 2
            )
            try imp(
                start: (year: 2024, month: 02, day: 29, hour: 07, minute: 00),
                end: (year: 2024, month: 03, day: 03, hour: 07, minute: 15),
                fn: cal.countDistinctWeeks(from:to:),
                expected: 2
            )
        }
        try withRegion(.berlin) {
            try imp(
                start: (year: 2021, month: 02, day: 07, hour: 07, minute: 00),
                end: (year: 2021, month: 02, day: 08, hour: 07, minute: 15),
                fn: cal.countDistinctWeeks(from:to:),
                expected: 2
            )
            try imp(
                start: (year: 2024, month: 12, day: 29, hour: 07, minute: 00),
                end: (year: 2025, month: 01, day: 02, hour: 07, minute: 15),
                fn: cal.countDistinctWeeks(from:to:),
                expected: 2
            )
        }
        
        try withRegions(.current, .losAngeles, .berlin) {
            try imp(
                start: (year: 2024, month: 12, day: 30, hour: 07, minute: 00),
                end: (year: 2025, month: 01, day: 02, hour: 07, minute: 15),
                fn: cal.countDistinctWeeks(from:to:),
                expected: 1
            )
            
            try imp(
                start: (year: 2022, month: 01, day: 12, hour: 05, minute: 00),
                end: (year: 2022, month: 08, day: 11, hour: 17, minute: 00),
                fn: cal.countDistinctMonths(from:to:),
                expected: 8
            )
            
            try imp(
                start: (year: 2022, month: 01, day: 12, hour: 05, minute: 00),
                end: (year: 2022, month: 08, day: 11, hour: 17, minute: 00),
                fn: cal.countDistinctYears(from:to:),
                expected: 1
            )
            try imp(
                start: (year: 2022, month: 01, day: 12, hour: 05, minute: 00),
                end: (year: 2023, month: 08, day: 11, hour: 17, minute: 00),
                fn: cal.countDistinctYears(from:to:),
                expected: 2
            )
        }
    }
    
    @Test
    func testOffsets() throws {
        try withRegions(.current, .losAngeles, .berlin) {
            let now = Date()
            #expect(cal.offsetInDays(
                from: now,
                to: now
            ) == 0)
            
            try #require(try cal.offsetInDays(
                from: makeDate(year: 2024, month: 01, day: 01, hour: 00),
                to: makeDate(year: 2024, month: 01, day: 08, hour: 00)
            ) == 7)
            
            try #require(try cal.offsetInDays(
                from: makeDate(year: 2024, month: 01, day: 08, hour: 00),
                to: makeDate(year: 2024, month: 01, day: 01, hour: 00)
            ) == -7)
            
            try #require(try cal.offsetInDays(
                from: makeDate(year: 2025, month: 02, day: 27, hour: 00),
                to: makeDate(year: 2025, month: 03, day: 02, hour: 00)
            ) == 3)
            try #require(try cal.offsetInDays(
                from: makeDate(year: 2024, month: 02, day: 27, hour: 00),
                to: makeDate(year: 2024, month: 03, day: 02, hour: 00)
            ) == 4)
        }
    }
    
    @Test
    func testRelativeOperations() throws {
        try withRegions(.current, .losAngeles, .berlin) {
            try #require(
                try cal.startOfPrevDay(for: makeDate(year: 2025, month: 01, day: 11, hour: 19, minute: 07)) ==
                makeDate(year: 2025, month: 01, day: 10, hour: 00, minute: 00)
            )
            
            try #require(
                try cal.startOfNextMonth(for: makeDate(year: 2025, month: 01, day: 11, hour: 19, minute: 07)) ==
                makeDate(year: 2025, month: 02, day: 01, hour: 00, minute: 00)
            )
            try #require(
                try cal.startOfPrevYear(for: makeDate(year: 2025, month: 01, day: 11, hour: 19, minute: 07)) ==
                makeDate(year: 2024, month: 01, day: 01, hour: 00, minute: 00)
            )
        }
    }
    
    @Test
    func testNumberOfDaysInMonth() throws {
        try withRegions(.current, .losAngeles, .berlin) {
            try #require(cal.numberOfDaysInMonth(for: makeDate(year: 2025, month: 1, day: 01, hour: 00)) == 31)
            try #require(cal.numberOfDaysInMonth(for: makeDate(year: 2024, month: 12, day: 01, hour: 00)) == 31)
            try #require(cal.numberOfDaysInMonth(for: makeDate(year: 2024, month: 11, day: 01, hour: 00)) == 30)
            try #require(cal.numberOfDaysInMonth(for: makeDate(year: 2025, month: 02, day: 01, hour: 00)) == 28)
            try #require(cal.numberOfDaysInMonth(for: makeDate(year: 2024, month: 02, day: 01, hour: 00)) == 29)
        }
    }
}
