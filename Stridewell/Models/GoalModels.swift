//
//  GoalModels.swift
//  Stridewell
//
//  Response model for GET /plan/goal-summary and computed helpers
//  used by GoalCardView.
//

import Foundation

struct GoalSummary: Codable {
    let goal_race_date: String?        // "YYYY-MM-DD" — nil for fitness/base-building goals
    let goal_race_distance_m: Double?  // metres — nil when no race goal
    let plan_start_date: String        // "YYYY-MM-DD"
    let horizon_days: Int
    let total_distance_m: Double       // sum of all runs since plan_start_date

    // MARK: - Computed

    /// Human-readable goal/race name derived from distance.
    var goalName: String {
        guard let dist = goal_race_distance_m else { return "Training Goal" }
        switch dist {
        case ..<5500:          return "5K"
        case 5500..<9000:      return "8K"
        case 9000..<11000:     return "10K"
        case 11000..<16000:    return "15K"
        case 16000..<19000:    return "10 Mile"
        case 19000..<23000:    return "Half Marathon"
        case 23000..<38000:    return "30K"
        default:               return "Marathon"
        }
    }

    /// Total weeks in the plan.
    var totalWeeks: Int {
        Int(ceil(Double(horizon_days) / 7.0))
    }

    /// Weeks elapsed since plan start, clamped to totalWeeks.
    var weeksCompleted: Int {
        guard let start = DateUtils.parse(plan_start_date) else { return 0 }
        let days = Calendar.current.dateComponents([.day], from: start, to: Date()).day ?? 0
        return min(max(days / 7, 0), totalWeeks)
    }

    /// 0.0–1.0 fill value for the progress bar.
    var weekProgress: Double {
        totalWeeks > 0 ? Double(weeksCompleted) / Double(totalWeeks) : 0
    }

    /// Total distance converted to miles.
    var totalMiles: Double {
        total_distance_m / 1609.34
    }

    /// Race date formatted as "March 7th" for display.
    var formattedRaceDate: String? {
        guard let dateStr = goal_race_date,
              let date = DateUtils.parse(dateStr) else { return nil }
        let day = Calendar.current.component(.day, from: date)
        let monthName = GoalSummary.monthFormatter.string(from: date)
        let ordinal = GoalSummary.ordinalFormatter.string(from: NSNumber(value: day)) ?? "\(day)"
        return "\(monthName) \(ordinal)"
    }

    private static let monthFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "MMMM"
        return f
    }()

    private static let ordinalFormatter: NumberFormatter = {
        let f = NumberFormatter()
        f.numberStyle = .ordinal
        return f
    }()
}
