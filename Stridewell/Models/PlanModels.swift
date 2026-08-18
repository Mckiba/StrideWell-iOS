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

    // Completion state, annotated at the API boundary. Both fields
    // are optional so cached pre-Phase-6 payloads still decode; nil status
    // renders as `.planned`.
    let status: Status?
    let runId: String?

    // hen status is .completed/.modified, the API embeds the
    // matched Run inline so the WorkoutCard's Completed variant can render the
    // map and actual stats without a separate fetch or cache lookup.
    let linkedRun: Run?

    enum Status: String, Codable {
        case planned, completed, missed, modified, rest
    }

    enum CodingKeys: String, CodingKey {
        case date, workout, notes, status
        case runId = "run_id"
        case linkedRun = "linked_run"
    }

    /// Memberwise init with status/runId/linkedRun defaulted to nil. Lets
    /// existing preview and fixture PlanDay literals compile without changes.
    init(
        date: String,
        workout: Workout,
        notes: String?,
        status: Status? = nil,
        runId: String? = nil,
        linkedRun: Run? = nil
    ) {
        self.date = date
        self.workout = workout
        self.notes = notes
        self.status = status
        self.runId = runId
        self.linkedRun = linkedRun
    }

    /// Custom decoder so a malformed `linked_run` (e.g. a future field drift on
    /// the embedded Run) degrades that one day to `linkedRun == nil` instead of
    /// failing the entire `[PlanDay]` decode and blanking the plan screen. The
    /// card then falls back to its planned layout rather than the whole week
    /// silently reverting to stale cached data.
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        date = try c.decode(String.self, forKey: .date)
        workout = try c.decode(Workout.self, forKey: .workout)
        notes = try c.decodeIfPresent(String.self, forKey: .notes)
        status = try c.decodeIfPresent(Status.self, forKey: .status)
        runId = try c.decodeIfPresent(String.self, forKey: .runId)
        linkedRun = (try? c.decodeIfPresent(Run.self, forKey: .linkedRun)) ?? nil
    }
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
