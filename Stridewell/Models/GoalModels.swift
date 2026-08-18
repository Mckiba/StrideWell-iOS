//
//  GoalModels.swift
//  Stridewell
//
//  Response model for GET /plan/goal-summary and computed helpers
//  used by GoalCardView. 
//

import Foundation

struct GoalSummary: Codable {
    let goal_type: String                    // "race" | "fitness"
    let goal_race_date: String?              // "YYYY-MM-DD" — nil for fitness goals
    let goal_race_distance_m: Double?        // metres — nil for fitness goals
    let goal_race_distance_label: String?    // server-formatted label, e.g. "Half marathon"
    let plan_start_date: String              // "YYYY-MM-DD"
    let horizon_days: Int
    let weeks_elapsed: Int
    let weeks_remaining: Int
    let runs_completed: Int
    let runs_planned_to_date: Int
    let distance_completed_m: Double         // plan-attributable distance only

    // MARK: - Computed

    /// Human-readable goal label. Prefers the server-rendered label; falls back
    /// to a local lookup when the server didn't provide one.
    var goalName: String {
        if let label = goal_race_distance_label, !label.isEmpty { return label }
        guard goal_type == "race", let dist = goal_race_distance_m else { return "Training Goal" }
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

    /// Total weeks in the plan (derived from horizon_days).
    var totalWeeks: Int {
        Int(ceil(Double(horizon_days) / 7.0))
    }

    /// Weeks elapsed (server-computed, clamped). Kept as a property name iOS
    /// callers already use.
    var weeksCompleted: Int { weeks_elapsed }

    /// 0.0–1.0 fill value for the progress bar.
    var weekProgress: Double {
        totalWeeks > 0 ? Double(weeks_elapsed) / Double(totalWeeks) : 0
    }

    /// Plan-attributable run completion as a 0.0–1.0 ratio.
    var runProgress: Double {
        runs_planned_to_date > 0
            ? min(1.0, Double(runs_completed) / Double(runs_planned_to_date))
            : 0
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
