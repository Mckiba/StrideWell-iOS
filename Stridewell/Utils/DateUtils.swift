//
//  DateUtils.swift
//  Stridewell
//
//  Shared date utilities — Monday-of-week computation, week navigation,
//  range labels, and YYYY-MM-DD formatting.
//

import Foundation

enum DateUtils {

    // MARK: - Shared Formatter

    /// POSIX formatter for YYYY-MM-DD strings.
    static let isoDate: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        f.locale = Locale(identifier: "en_US_POSIX")
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

    // MARK: - Parse / Format

    /// Parse a YYYY-MM-DD string into a Date.
    static func parse(_ dateString: String) -> Date? {
        isoDate.date(from: dateString)
    }

    /// Format a Date as YYYY-MM-DD.
    static func format(_ date: Date) -> String {
        isoDate.string(from: date)
    }
}
