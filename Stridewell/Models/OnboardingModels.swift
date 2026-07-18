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
    let conversation_id: String?      // present once the interview has started

    // Optional so responses from a backend that omits them still decode.
    let history_summary: StravaHistorySummary?   // present when Strava is connected
    let confirmed_fields: [String]?              // intake keys confirmed so far; drives which screen shows next
    let partial_intake: PartialIntake?           // confirmed values so far; pre-fills the structured controls
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

// MARK: - Interview message types

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
    // Both optional; the synthesized encoder omits nil, so the body matches a plain
    // free-text turn when unset.
    var screen_context: String?
    var structured_fields: StructuredFields?
}

// onboarding_state field inside POST /onboarding/message response
struct OnboardingMessageOnboardingState: Codable {
    let status: OnboardingStatus
    let intake_complete: Bool
    let plan_building: Bool
    let first_plan_version_id: String?
    let confirmed_fields: [String]?   // intake keys confirmed so far
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

// MARK: - Structured input payload

/// Intake values a guided control submits directly instead of relying on the model to
/// re-read them from the message text. Every field is optional; the encoder emits only
/// the ones that are set. The set of keys matches what the backend accepts here.
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

// MARK: - Partial intake (pre-fill on return)

/// The values confirmed so far, echoed by the status endpoint. Every field is optional
/// so any subset decodes; each screen reads the keys it owns to pre-fill its controls.
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

// MARK: - Strava history summary

/// One week in the volume-history series. Values are in km; the UI converts to the
/// athlete's display unit.
struct HistoryWeekVolume: Codable, Identifiable {
    let week_start: String   // YYYY-MM-DD, Monday of the week
    let volume_km: Double

    var id: String { week_start }
}

/// Computed training history echoed by the status endpoint when Strava is connected.
/// Only the fields the app displays or branches on are modeled; unknown keys are ignored.
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
    /// Last 12 weeks, oldest first. Optional: summaries stored before this field
    /// existed decode without it and the card falls back to stats only.
    let weekly_volumes: [HistoryWeekVolume]?

    init(
        avg_weekly_volume_km_4wk: Double?,
        avg_weekly_volume_km_12wk: Double?,
        peak_weekly_volume_km_12wk: Double?,
        recent_long_run_m: Double?,
        avg_runs_per_week_4wk: Double?,
        consistency_rate_12wk: Double?,
        has_speed_work: Bool?,
        inferred_training_phase: String?,
        volume_trend: String?,
        weekly_volumes: [HistoryWeekVolume]? = nil
    ) {
        self.avg_weekly_volume_km_4wk = avg_weekly_volume_km_4wk
        self.avg_weekly_volume_km_12wk = avg_weekly_volume_km_12wk
        self.peak_weekly_volume_km_12wk = peak_weekly_volume_km_12wk
        self.recent_long_run_m = recent_long_run_m
        self.avg_runs_per_week_4wk = avg_runs_per_week_4wk
        self.consistency_rate_12wk = consistency_rate_12wk
        self.has_speed_work = has_speed_work
        self.inferred_training_phase = inferred_training_phase
        self.volume_trend = volume_trend
        self.weekly_volumes = weekly_volumes
    }
}
