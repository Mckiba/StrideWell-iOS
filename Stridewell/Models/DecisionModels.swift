//
//  DecisionModels.swift
//  Stridewell
//

import Foundation

enum DecisionTrigger: String, Codable {
    case new_activity
    case missed_workout
    case reflection_submitted
    case user_requested_recalc
    case fatigue_flag
    case injury_flag
    case onboarding
}

struct SignalsUsed: Codable {
    let fatigue_trend: String?
    let injury_risk_level: String?
    let compliance_rate: Double?
    let intake_confidence: String?
    let strava_connected: Bool?
}

struct DecisionRecord: Codable, Identifiable {
    var id: String { decision_id }
    let decision_id: String
    let user_id: String
    let created_at: String
    let trigger: DecisionTrigger
    let from_plan_version_id: String?  // null only for onboarding trigger
    let to_plan_version_id: String
    let diff_summary: [String]
    let rationale_bullets: [String]
    let signals_used: SignalsUsed?
    let guardrails_applied: [String]?
}

// MARK: - Response (M11)

struct LatestDecisionResponse: Decodable {
    let decision_record: DecisionRecord
}
