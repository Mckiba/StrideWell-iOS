//
//  PlanModels.swift
//  Stridewell
//

import Foundation

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
