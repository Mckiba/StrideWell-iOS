//
//  PlanModels.swift
//  Stridewell
//

import Foundation

// MARK: - Plan API response types (M6+)

/// One week chunk from GET /plan/version/:id
struct PlanVersionWeek: Codable {
    let week_number: Int
    let start_date: String
    let days: [PlanDay]
}

/// Full response from GET /plan/version/:id
struct PlanVersionResponse: Codable {
    let plan_version_id: String
    let source: PlanSource
    let start_date: String
    let horizon_days: Int
    let phase_label: String?
    let coaching_notes: String?
    let rationale_bullets: [String]?
    let warning_flags: [String]?
    let weeks: [PlanVersionWeek]
}

/// Response from GET /plan/week (used by HomeScreen M7, PlanScreen M8)
struct PlanWeekResponse: Codable {
    let plan_version_id: String
    let start_date: String
    let days: [PlanDay]
    let phase_label: String?
    let coaching_notes: String?
    let rationale_bullets: [String]?
    let warning_flags: [String]?
}

/// Response from POST /onboarding/confirm-plan
struct ConfirmPlanResponse: Codable {
    let confirmed: Bool
    let plan_version_id: String
}

// MARK: - Domain types

enum PlanSource: String, Codable {
    case architect
    case adjuster
    case manual
}

struct PlanDay: Codable, Identifiable {
    var id: String { date }
    let date: String  // YYYY-MM-DD
    let workout: Workout
    let notes: String?
}

struct PlanVersion: Codable {
    let plan_version_id: String
    let user_id: String
    let source: PlanSource
    let start_date: String
    let horizon_days: Int
    let created_at: String
    let days: [PlanDay]
    // Architect-only presentation fields
    let phase_label: String?
    let rationale_bullets: [String]?
    let coaching_notes: String?
    let warning_flags: [String]?
}
