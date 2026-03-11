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
        let withFractional = ISO8601DateFormatter()
        withFractional.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = withFractional.date(from: iso) { return date }
        return ISO8601DateFormatter().date(from: iso)
    }

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
}
