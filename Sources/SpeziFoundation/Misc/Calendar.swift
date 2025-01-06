//
//  File.swift
//  SpeziFoundation
//
//  Created by Lukas Kollmer on 2024-12-17.
//

import Foundation




// MARK: Date Ranges


extension Calendar {
    /// Returns a `Date` which represents the start of the hour into which `date` falls.
    public func startOfHour(for date: Date) -> Date {
        var retval = date
        for component in [Calendar.Component.minute, .second, .nanosecond] {
            retval = self.date(bySettingComponentToZero: component, of: retval, adjustOtherComponents: false)
        }
        precondition([Component.year, .month, .day, .hour].allSatisfy {
            self.component($0, from: retval) == self.component($0, from: date)
        })
        return retval
    }
    
    /// Returns a `Date` which represents the start of the next hour, relative to `date`.
    public func startOfNextHour(for date: Date) -> Date {
        let startOfHour = startOfHour(for: date)
        return self.date(byAdding: .hour, value: 1, to: startOfHour)!
    }
    
    /// Returns a `Range<Date>` representing the range of the hour into which `date` falls.
    public func rangeOfHour(for date: Date) -> Range<Date> {
        return startOfHour(for: date)..<startOfNextHour(for: date)
    }

    
    /// Returns a `Date` which represents the start of the next day, relative to `date`.
    public func startOfNextDay(for date: Date) -> Date {
        let startOfDay = self.startOfDay(for: date)
        return self.date(byAdding: .day, value: 1, to: startOfDay)!
    }
    
    /// Returns a `Date` which represents the start of the previous day, relative to `date`.
    public func startOfPrevDay(for date: Date) -> Date {
        let startOfDay = self.startOfDay(for: date)
        return self.date(byAdding: .day, value: -1, to: startOfDay)!
    }
    
    /// Returns a `Range<Date>` representing the range of the day into which `date` falls.
    public func rangeOfDay(for date: Date) -> Range<Date> {
        return startOfDay(for: date)..<startOfNextDay(for: date)
    }
    
    
    /// Returns a `Date` which represents the start of the week into which `date` falls.
    public func startOfWeek(for date: Date) -> Date {
        let date = self.startOfDay(for: date)
        var weekday = self.component(.weekday, from: date)
        // We have to adjust the weekday to avoid going into the next week instead.
        // The issue here is that firstWeekday can be larger than the current weekday,
        // in which case `weekdayDiff` is a) negative and b) incorrect, even if we look at the absolute value.
        // Example: We're in the german locale (firstWeekday = Monday) and the day represents a Sunday.
        // Since `Calendar`'s weekday numbers start at Sunday=1, we'd calculate diff = sunday - firstWeekday = sunday - monday = 1 - 2 = -1.
        // But what we actually want is diff = sunday - monday = 6
        if weekday < self.firstWeekday {
            weekday += self.weekdaySymbols.count
        }
        let weekdayDiff = weekday - self.firstWeekday
        return self.date(byAdding: .weekday, value: -weekdayDiff, to: date)!
    }
    
    /// Returns a `Date` which represents the start of the next week, relative to `date`.
    public func startOfNextWeek(for date: Date) -> Date {
        let start = startOfWeek(for: date)
        return self.date(byAdding: .weekOfYear, value: 1, to: start)!
    }
    
    /// Returns a `Range<Date>` representing the range of the week into which `date` falls.
    public func rangeOfWeek(for date: Date) -> Range<Date> {
        return startOfWeek(for: date)..<startOfNextWeek(for: date)
    }
    
    
    /// Returns a `Date` which represents the start of the month into which `date` falls.
    public func startOfMonth(for date: Date) -> Date {
        var adjustedDate = self.startOfDay(for: date)
        adjustedDate = self.date(bySetting: .day, value: 1, of: adjustedDate)!
        if adjustedDate <= date {
            precondition(self.component(.day, from: adjustedDate) == 1)
            return adjustedDate
        } else {
            let startOfMonth = self.date(byAdding: .month, value: -1, to: adjustedDate)!
            precondition(self.component(.day, from: startOfMonth) == 1)
            return startOfMonth
        }
    }
    
    /// Returns a `Date` which represents the start of the next month, relative to `date`.
    public func startOfNextMonth(for date: Date) -> Date {
        let start = startOfMonth(for: date)
        return self.date(byAdding: .month, value: 1, to: start)!
    }
    
    
    /// Returns the exclusive range from the beginning of the month into which `date` falls, to the beginning of the next
    public func rangeOfMonth(for date: Date) -> Range<Date> {
        let start = startOfMonth(for: date)
        let end = startOfNextMonth(for: start)
        precondition(startOfNextMonth(for: start) == startOfNextMonth(for: date))
        return start..<end
    }
    
    
    /// Returns a `Date` which represents the start of the year into which `date` falls.
    public func startOfYear(for date: Date) -> Date {
        var adjustedDate = startOfMonth(for: date)
        precondition(adjustedDate <= date)
        adjustedDate = self.date(bySetting: .month, value: 1, of: adjustedDate)!
        if adjustedDate > date {
            // Setting the month to 1 made the date larger, i.e. moved it one year ahead :/
            adjustedDate = self.date(byAdding: .year, value: -1, to: adjustedDate)!
            return adjustedDate
        }
        
        precondition({ () -> Bool in
            let components = self.dateComponents([.year, .month, .day, .hour, .minute, .second, .nanosecond], from: adjustedDate)
            return components.year == self.component(.year, from: date) && components.month == 1 && components.day == 1
                && components.hour == 0 && components.minute == 0 && components.second == 0 && components.nanosecond == 0
        }())
        return adjustedDate
    }
    
    
    /// Returns a `Date` which represents the start of the previous year, relative to `date`.
    public func startOfPrevYear(for date: Date) -> Date {
        return self.date(byAdding: .year, value: -1, to: startOfYear(for: date))!
    }
    
    /// Returns a `Date` which represents the start of the next year, relative to `date`.
    public func startOfNextYear(for date: Date) -> Date {
        return self.date(byAdding: .year, value: 1, to: startOfYear(for: date))!
    }
    
    /// Returns a `Range<Date>` representing the range of the year into which `date` falls.
    public func rangeOfYear(for date: Date) -> Range<Date> {
        return startOfYear(for: date)..<startOfNextYear(for: date)
    }
}





// MARK: Date Distances


extension Calendar {
    private func _countDistinctNumberOfComponentUnits(
        from startDate: Date,
        to endDate: Date,
        for component: Calendar.Component,
        startOfComponentFn: (Date) -> Date
    ) -> Int {
        guard startDate <= endDate else {
            return _countDistinctNumberOfComponentUnits(
                from: endDate,
                to: startDate,
                for: component,
                startOfComponentFn: startOfComponentFn
            )
        }
        if startDate == endDate {
            return 1
        } else if self.isDate(startDate, equalTo: endDate, toGranularity: component) {
            return 1
        } else {
            let diff = self.dateComponents(
                [component],
                from: startOfComponentFn(startDate),
                to: startOfComponentFn(endDate)
            )
            return diff[component]! + 1
        }
    }
    
    
    public func countDistinctYears(from startDate: Date, to endDate: Date) -> Int {
        _countDistinctNumberOfComponentUnits(
            from: startDate,
            to: endDate,
            for: .year,
            startOfComponentFn: startOfYear
        )
    }
    
    /// Returns the rounded up number of months between the two dates.
    /// E.g., if the first date is 25.02 and the second is 12.04, this would return 3.
    public func countDistinctMonths(from startDate: Date, to endDate: Date) -> Int {
        _countDistinctNumberOfComponentUnits(
            from: startDate,
            to: endDate,
            for: .month,
            startOfComponentFn: startOfMonth
        )
    }
    
    public func countDistinctWeeks(from startDate: Date, to endDate: Date) -> Int {
        _countDistinctNumberOfComponentUnits(
            from: startDate,
            to: endDate,
            for: .weekOfYear,
            startOfComponentFn: startOfWeek
        )
    }
    
    
    public func countDistinctDays(from startDate: Date, to endDate: Date) -> Int {
        _countDistinctNumberOfComponentUnits(
            from: startDate,
            to: endDate,
            for: .day,
            startOfComponentFn: startOfDay
        )
    }
    
    
    public func countDistinctHours(from startDate: Date, to endDate: Date) -> Int {
        _countDistinctNumberOfComponentUnits(
            from: startDate,
            to: endDate,
            for: .hour,
            startOfComponentFn: startOfHour
        )
    }
    
    
    public func offsetInDays(from startDate: Date, to endDate: Date) -> Int {
        guard !isDate(startDate, inSameDayAs: endDate) else {
            return 0
        }
        if startDate < endDate {
            return countDistinctDays(from: startDate, to: endDate) - 1
        } else {
            return -(countDistinctDays(from: endDate, to: startDate) - 1)
        }
    }
    
    
    public func dateIsSunday(_ date: Date) -> Bool {
        // NSCalendar starts weeks on sundays, ?regardless of locale?
        return self.component(.weekday, from: date) == self.firstWeekday
    }
    
    
    public func numberOfDaysInMonth(for date: Date) -> Int {
        return self.range(of: .day, in: .month, for: date)!.count
    }
}




// MARK: Date Components


extension Calendar {
    public func date(bySettingComponentToZero component: Component, of date: Date, adjustOtherComponents: Bool) -> Date {
        if adjustOtherComponents {
            return self.date(bySetting: component, value: 0, of: date)!
        } else {
            let compValue = self.component(component, from: date)
            return self.date(byAdding: component, value: -compValue, to: date, wrappingComponents: true)!
        }
    }
    
    
    
    public func date(bySetting component: Component, of date: Date, to value: Int, adjustOtherComponents: Bool) -> Date {
        if adjustOtherComponents {
            return self.date(bySetting: component, value: value, of: date)!
        } else {
            let compValue = self.component(component, from: date)
            let diff = value - compValue
            return self.date(byAdding: component, value: diff, to: date, wrappingComponents: true)!
        }
    }
}




extension DateComponents {
    public subscript(component: Calendar.Component) -> Int? {
        switch component {
        case .era:
            return self.era
        case .year:
            return self.year
        case .month:
            return self.month
        case .day:
            return self.day
        case .hour:
            return self.hour
        case .minute:
            return self.minute
        case .second:
            return self.second
        case .weekday:
            return self.weekday
        case .weekdayOrdinal:
            return self.weekdayOrdinal
        case .quarter:
            return self.quarter
        case .weekOfMonth:
            return self.weekOfMonth
        case .weekOfYear:
            return self.weekOfYear
        case .yearForWeekOfYear:
            return self.yearForWeekOfYear
        case .nanosecond:
            return self.nanosecond
        case .dayOfYear:
            if #available(iOS 18, macOS 15, *) {
                return self.dayOfYear
            } else {
                // The crash here is fine, since the enum case itself is also only available on iOS 18+
                fatalError()
            }
        case .calendar, .timeZone, .isLeapMonth:
            fatalError("not supported") // different type (not an int) :/
        @unknown default:
            return nil
        }
    }
}


