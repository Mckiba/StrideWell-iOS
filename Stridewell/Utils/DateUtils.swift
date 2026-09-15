//
//  DateUtils.swift
//  Stridewell
//
//  Shared date utilities — Monday-of-week computation, week navigation,
//  range labels, ISO-8601 parsing, and display formatting.
//
//  All date formatter instances are static so they are created once and
//  shared across the app.  Views should use the formatting helpers rather
//  than constructing their own DateFormatter/ISO8601DateFormatter instances.
//

import Foundation

enum DateUtils {

    // MARK: - YYYY-MM-DD Formatter

    /// POSIX formatter for YYYY-MM-DD strings (plan dates, week keys).
    static let isoDate: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        f.locale = Locale(identifier: "en_US_POSIX")
        return f
    }()

    // MARK: - ISO-8601 DateTime Formatters

    /// Full ISO-8601 formatter with fractional seconds (used when creating
    /// outgoing message timestamps).
    static let isoDateTimeFormatter: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime]
        return f
    }()

    /// Parses an ISO-8601 string, trying fractional seconds first, then
    /// without.  Returns nil only if the string cannot be parsed at all.
    static func parseISO8601(_ iso: String) -> Date? {
        if let date = fractionalParser.date(from: iso) { return date }
        return plainParser.date(from: iso)
    }

    private static let fractionalParser: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return f
    }()

    private static let plainParser = ISO8601DateFormatter()

    // MARK: - Display Formatters

    /// "Mar 8, 2026 at 3:00 PM"
    static func displayDateTime(_ iso: String) -> String {
        guard let date = parseISO8601(iso) else { return String(iso.prefix(10)) }
        return displayDateTimeFormatter.string(from: date)
    }

    /// "Mar 8, 2026"
    static func displayDate(_ iso: String) -> String {
        guard let date = parseISO8601(iso) else { return String(iso.prefix(10)) }
        return displayDateFormatter.string(from: date)
    }

    private static let displayDateTimeFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .short
        return f
    }()

    private static let displayDateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .none
        return f
    }()

    // MARK: - Activity Card Formatters

    /// "February 18, 2025" — apply .textCase(.uppercase) in the view.
    static func activityDate(_ iso: String) -> String {
        guard let date = parseISO8601(iso) else { return String(iso.prefix(10)) }
        return activityDateFormatter.string(from: date)
    }

    /// "6:16 PM" — apply .textCase(.uppercase) in the view.
    static func activityTime(_ iso: String) -> String {
        guard let date = parseISO8601(iso) else { return "" }
        return activityTimeFormatter.string(from: date)
    }

    private static let activityDateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "MMMM d, yyyy"
        return f
    }()

    private static let activityTimeFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "h:mm a"
        f.amSymbol = "AM"
        f.pmSymbol = "PM"
        return f
    }()

    // MARK: - Plan Day Date Formatter

    /// "Friday, March 20" — for YYYY-MM-DD plan day dates shown on the home screen.
    static func planDayDate(_ dateString: String) -> String {
        guard let date = parse(dateString) else { return dateString }
        return planDayDateFormatter.string(from: date)
    }

    private static let planDayDateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "EEEE, MMMM d"
        return f
    }()

    // MARK: - Workout Date Formatters (used by WorkoutCardView)

    /// Abbreviated day name: "Mon", "Tue", …
    static let dayAbbrevFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "EEE"
        return f
    }()

    /// Day number: "3", "14", …
    static let dayNumberFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "d"
        return f
    }()

    /// Card-style date: "Monday, Feb 23"
    static let workoutCardDateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "EEEE, MMM d"
        return f
    }()

    // MARK: - Monday Computation

    /// Returns the Monday (ISO 8601 week start) of the week containing `date`.
    /// Sunday is treated as the end of the prior week.
    static func mondayOfWeek(containing date: Date) -> Date {
        let calendar = Calendar.current
        let weekday = calendar.component(.weekday, from: date)
        // .weekday: Sunday=1, Monday=2, ..., Saturday=7
        let daysToSubtract = (weekday == 1) ? 6 : weekday - 2
        return calendar.date(byAdding: .day, value: -daysToSubtract, to: date)!
    }

    /// ISO string ("YYYY-MM-DD") for the Monday of the week containing `date`.
    static func mondayString(containing date: Date) -> String {
        format(mondayOfWeek(containing: date))
    }

    // MARK: - Week Navigation

    /// Returns the Monday one week before the given Monday.
    static func previousMonday(from monday: Date) -> Date {
        Calendar.current.date(byAdding: .day, value: -7, to: monday)!
    }

    /// Returns the Monday one week after the given Monday.
    static func nextMonday(from monday: Date) -> Date {
        Calendar.current.date(byAdding: .day, value: 7, to: monday)!
    }

    // MARK: - Display

    /// Human-readable week range: "Mar 3 – 9" or "Feb 24 – Mar 2" (cross-month).
    static func weekRangeLabel(monday: Date) -> String {
        let calendar = Calendar.current
        let sunday = calendar.date(byAdding: .day, value: 6, to: monday)!

        let monMonth = calendar.component(.month, from: monday)
        let sunMonth = calendar.component(.month, from: sunday)

        let monthDay = DateFormatter()
        monthDay.dateFormat = "MMM d"
        let dayOnly = DateFormatter()
        dayOnly.dateFormat = "d"

        if monMonth == sunMonth {
            return "\(monthDay.string(from: monday)) – \(dayOnly.string(from: sunday))"
        } else {
            return "\(monthDay.string(from: monday)) – \(monthDay.string(from: sunday))"
        }
    }

    // MARK: - Parse / Format (YYYY-MM-DD)

    /// Parse a YYYY-MM-DD string into a Date.
    static func parse(_ dateString: String) -> Date? {
        isoDate.date(from: dateString)
    }

    /// Format a Date as YYYY-MM-DD.
    static func format(_ date: Date) -> String {
        isoDate.string(from: date)
    }

    // MARK: - Activity Periods

    /// Start of the `range` period containing `date`: its Monday, the 1st of its
    /// month, or January 1st.
    static func periodStart(for range: ActivityRange, containing date: Date) -> Date {
        let calendar = Calendar.current
        switch range {
        case .week:
            return calendar.startOfDay(for: mondayOfWeek(containing: date))
        case .month:
            return calendar.date(from: calendar.dateComponents([.year, .month], from: date))!
        case .year, .all:
            return calendar.date(from: calendar.dateComponents([.year], from: date))!
        }
    }

    /// Start of the period before the one starting at `start`.
    static func previousPeriodStart(for range: ActivityRange, from start: Date) -> Date {
        let calendar = Calendar.current
        switch range {
        case .week:       return calendar.date(byAdding: .day, value: -7, to: start)!
        case .month:      return calendar.date(byAdding: .month, value: -1, to: start)!
        case .year, .all: return calendar.date(byAdding: .year, value: -1, to: start)!
        }
    }

    /// Period starts from the current period back to the one containing
    /// `firstRunDate`, newest first. Empty for `.all`, which has a single period.
    static func periodStarts(for range: ActivityRange, back firstRunDate: Date?, today: Date = Date()) -> [Date] {
        guard range != .all else { return [] }
        let current = periodStart(for: range, containing: today)
        guard let firstRunDate else { return [current] }

        let oldest = periodStart(for: range, containing: firstRunDate)
        var starts = [current]
        var cursor = previousPeriodStart(for: range, from: current)
        while cursor >= oldest {
            starts.append(cursor)
            cursor = previousPeriodStart(for: range, from: cursor)
        }
        return starts
    }

    /// Dropdown label: "This Week", "Last Week", "Sep 1 – 7", "This Month",
    /// "August", "Aug 2025", "This Year", "2025", "All Time".
    static func periodLabel(for range: ActivityRange, start: Date, today: Date = Date()) -> String {
        let current = periodStart(for: range, containing: today)
        switch range {
        case .week:
            if start == current { return "This Week" }
            if start == previousPeriodStart(for: .week, from: current) { return "Last Week" }
            return weekRangeLabel(monday: start)
        case .month:
            if start == current { return "This Month" }
            let monthsBack = Calendar.current.dateComponents([.month], from: start, to: current).month ?? 0
            return (monthsBack < 12 ? monthNameFormatter : monthYearFormatter).string(from: start)
        case .year:
            return start == current ? "This Year" : yearFormatter.string(from: start)
        case .all:
            return "All Time"
        }
    }

    /// Section title for runs before today in the current period.
    static func earlierLabel(for range: ActivityRange) -> String {
        switch range {
        case .week:  return "Earlier This Week"
        case .month: return "Earlier This Month"
        case .year:  return "Earlier This Year"
        case .all:   return "Earlier"
        }
    }

    /// "February 18" — section title for a single day.
    static func sectionDayLabel(_ date: Date) -> String {
        monthDayFormatter.string(from: date)
    }

    /// Short x-axis label for a summary bucket key: weekday initial, day of
    /// month, month initial, or year.
    static func bucketAxisLabel(for range: ActivityRange, key: String) -> String {
        switch range {
        case .week:
            return parse(key).map { weekdayInitialFormatter.string(from: $0) } ?? key
        case .month:
            return parse(key).map { dayNumberFormatter.string(from: $0) } ?? key
        case .year:
            return bucketMonthFormatter.date(from: key).map { monthInitialFormatter.string(from: $0) } ?? key
        case .all:
            return key
        }
    }

    /// Callout title for a summary bucket key: "Mon, Sep 14", "September 2026", "2026".
    static func bucketTitle(for range: ActivityRange, key: String) -> String {
        switch range {
        case .week, .month:
            return parse(key).map { weekdayMonthDayFormatter.string(from: $0) } ?? key
        case .year:
            return bucketMonthFormatter.date(from: key).map { monthYearLongFormatter.string(from: $0) } ?? key
        case .all:
            return key
        }
    }

    /// Inclusive first and last day covered by a summary bucket key.
    static func bucketWindow(for range: ActivityRange, key: String) -> (from: Date, to: Date)? {
        let calendar = Calendar.current
        switch range {
        case .week, .month:
            guard let day = parse(key) else { return nil }
            return (day, day)
        case .year:
            guard let start = bucketMonthFormatter.date(from: key),
                  let next = calendar.date(byAdding: .month, value: 1, to: start),
                  let last = calendar.date(byAdding: .day, value: -1, to: next) else { return nil }
            return (start, last)
        case .all:
            guard let start = parse("\(key)-01-01"), let last = parse("\(key)-12-31") else { return nil }
            return (start, last)
        }
    }

    private static func formatter(_ format: String, posix: Bool = false) -> DateFormatter {
        let f = DateFormatter()
        f.dateFormat = format
        if posix { f.locale = Locale(identifier: "en_US_POSIX") }
        return f
    }

    private static let monthNameFormatter       = formatter("MMMM")
    private static let monthYearFormatter       = formatter("MMM yyyy")
    private static let monthYearLongFormatter   = formatter("MMMM yyyy")
    private static let yearFormatter            = formatter("yyyy")
    private static let monthDayFormatter        = formatter("MMMM d")
    private static let weekdayInitialFormatter  = formatter("EEEEE")
    private static let monthInitialFormatter    = formatter("MMMMM")
    private static let weekdayMonthDayFormatter = formatter("EEE, MMM d")
    private static let bucketMonthFormatter     = formatter("yyyy-MM", posix: true)
}

// MARK: - Activity Range

/// Period granularity for the Activities overview.
enum ActivityRange: String, CaseIterable, Identifiable {
    case week, month, year, all

    var id: String { rawValue }

    /// Segment label in the range picker.
    var shortLabel: String {
        switch self {
        case .week:  return "W"
        case .month: return "M"
        case .year:  return "Y"
        case .all:   return "All"
        }
    }

    /// Spoken label for accessibility.
    var title: String {
        switch self {
        case .week:  return "Week"
        case .month: return "Month"
        case .year:  return "Year"
        case .all:   return "All Time"
        }
    }
}
