//
//  OnboardingModels.swift
//  Stridewell
//

import Foundation

enum OnboardingStatus: String, Codable {
    case pending
    case analyzing
    case interview
    case complete
    case skipped
}

// Returned by GET /onboarding/status
struct OnboardingState: Codable {
    let status: OnboardingStatus
    let strava_connected: Bool
    let intake_complete: Bool
    let first_plan_version_id: String?
    let conversation_id: String?      // present on resume; used by the interview screens

    // V2 (all optional → backward-compatible decode against a V1 backend)
    let history_summary: StravaHistorySummary?   // present on the Strava branch
    let confirmed_fields: [String]?              // intake keys confirmed so far (advancement signal)
    let partial_intake: PartialIntake?           // working state; pre-fills structured inputs on resume
}

// Returned by POST /onboarding/start
struct OnboardingStartResponse: Codable {
    let status: OnboardingStatus
    let strava_connected: Bool
    let conversation_id: String
}

// POST /oauth/strava/connect
struct StravaConnectRequest: Codable {
    let code: String
}

struct StravaConnectResponse: Codable {
    let connected: Bool
}

// MARK: - Interview message types (M4)

enum InterviewMessageRole: String, Codable {
    case user
    case assistant
}

struct InterviewMessage: Codable, Identifiable {
    let id: String
    let role: InterviewMessageRole
    let content: String
    let agent_used: String?
    let created_at: String
}

// POST /onboarding/message
struct OnboardingMessageRequest: Encodable {
    let conversation_id: String
    let message: InterviewMessage
    // V2 (both optional; synthesized Encodable omits nil → a V1-shaped body when unset)
    var screen_context: String?
    var structured_fields: StructuredFields?
}

// onboarding_state field inside POST /onboarding/message response
struct OnboardingMessageOnboardingState: Codable {
    let status: OnboardingStatus
    let intake_complete: Bool
    let plan_building: Bool
    let first_plan_version_id: String?
    let confirmed_fields: [String]?   // V2: intake keys confirmed so far
}

// Full POST /onboarding/message response
struct OnboardingMessageResponse: Codable {
    let conversation_id: String
    let reply: InterviewMessage
    let onboarding_state: OnboardingMessageOnboardingState
}

// POST /onboarding/skip → 202
struct OnboardingSkipResponse: Codable {
    let queued: Bool
    let message: String?
}

// MARK: - V2 structured input payload (subset of intake fields)

/// The whitelisted subset of intake fields a guided screen may submit deterministically.
/// All-optional: the synthesized encoder emits only set keys, matching the backend's
/// `onboarding_message_structured_fields.json` (`additionalProperties: false`).
struct StructuredFields: Codable {
    var current_weekly_volume_km: Double?
    var training_phase: String?
    var goal_type: String?
    var goal_race_date: String?          // YYYY-MM-DD
    var goal_race_distance_m: Double?
    var goal_time_seconds: Int?
    var available_days_per_week: Int?
    var available_day_names: [String]?
    var preferred_long_run_day: String?
    var rest_day_constraints: [String]?
    var has_done_speedwork: Bool?
    var following_existing_plan: Bool?

    /// True when no field is set — lets call sites avoid sending an empty object.
    var isEmpty: Bool {
        current_weekly_volume_km == nil && training_phase == nil && goal_type == nil &&
        goal_race_date == nil && goal_race_distance_m == nil && goal_time_seconds == nil &&
        available_days_per_week == nil && available_day_names == nil && preferred_long_run_day == nil &&
        rest_day_constraints == nil && has_done_speedwork == nil && following_existing_plan == nil
    }
}

// MARK: - V2 partial intake (resume pre-fill)

/// Echo of `onboarding_sessions.partial_intake`. All-optional so any subset decodes;
/// guided screens read the keys they own to pre-fill their structured controls.
struct PartialIntake: Codable {
    var current_weekly_volume_km: Double?
    var training_phase: String?
    var active_injury: Bool?
    var goal_type: String?
    var goal_race_date: String?
    var goal_race_distance_m: Double?
    var goal_time_seconds: Int?
    var available_days_per_week: Int?
    var available_day_names: [String]?
    var preferred_long_run_day: String?
    var rest_day_constraints: [String]?
    var has_done_speedwork: Bool?
    var following_existing_plan: Bool?
}

// MARK: - V2 Strava history summary (S2a render + branch routing)

/// Computed Strava history echoed by GET /onboarding/status on the Strava branch.
/// Only the fields the client needs are modeled; unknown keys are ignored.
struct StravaHistorySummary: Codable {
    let avg_weekly_volume_km_4wk: Double?
    let avg_weekly_volume_km_12wk: Double?
    let peak_weekly_volume_km_12wk: Double?
    let recent_long_run_m: Double?
    let avg_runs_per_week_4wk: Double?
    let consistency_rate_12wk: Double?
    let has_speed_work: Bool?
    let inferred_training_phase: String?   // may be "insufficient_data" → route to manual baseline
    let volume_trend: String?
}
