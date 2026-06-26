//
//  OnboardingFlow.swift
//  Stridewell
//
//  The single client-side source of truth for guided-flow screen ordering and
//  advancement (Onboarding V2 spec §1.1 / §4.3). Advancement is driven exclusively
//  by extraction state (`confirmed_fields`), never by turn count.
//

import Foundation

/// The ordered screens of the guided onboarding flow.
/// `historyConfirm` (S2a) and `manualBaseline` (S2b) are the two baseline branches;
/// the flow is linear after they converge at `goal` (S3).
enum OnboardingScreen: Hashable {
    case integrations    // S1
    case historyConfirm  // S2a (Strava branch)
    case manualBaseline  // S2b (no-Strava branch)
    case goal            // S3
    case routines        // S4
    case speedwork       // S5
    case lessons         // S6
    case planBuilding    // S7
    case planReveal      // S8
}

enum OnboardingFlow {

    /// The `screen_context` string sent to the backend for a given screen, or nil
    /// for screens that carry no intake topic (S1, S7, S8 → V1 free-form / non-chat).
    static func screenContext(for screen: OnboardingScreen) -> String? {
        switch screen {
        case .historyConfirm: return "history_confirm"
        case .manualBaseline: return "manual_baseline"
        case .goal:           return "goal"
        case .routines:       return "routines"
        case .speedwork:      return "speedwork"
        case .lessons:        return "lessons"
        case .integrations, .planBuilding, .planReveal: return nil
        }
    }

    /// The required intake fields that gate advancement off a screen. A screen is
    /// satisfied when all of these appear in `confirmed_fields`. (Spec §1.1.)
    static func requiredFields(for screen: OnboardingScreen) -> [String] {
        switch screen {
        case .historyConfirm, .manualBaseline:
            return ["current_weekly_volume_km", "training_phase", "active_injury"]
        case .goal:
            return ["goal_type"]
        case .routines:
            return ["available_days_per_week"]
        case .speedwork:
            return ["has_done_speedwork"]
        case .lessons:
            return ["what_hasnt_worked"]
        case .integrations, .planBuilding, .planReveal:
            return []   // not gated by intake fields
        }
    }

    /// The baseline branch (S2a vs S2b), recomputed from connection state — never stored.
    /// Strava with usable history → S2a; otherwise (no Strava, or insufficient data) → S2b.
    static func baselineBranch(
        stravaConnected: Bool,
        historySummary: StravaHistorySummary?
    ) -> OnboardingScreen {
        guard stravaConnected, let summary = historySummary else { return .manualBaseline }
        if summary.inferred_training_phase == "insufficient_data" { return .manualBaseline }
        return .historyConfirm
    }

    /// The linear order of the intake screens, given the chosen baseline branch.
    /// S1, S7, S8 are handled outside this sequence (entry and post-intake).
    static func intakeSequence(branch: OnboardingScreen) -> [OnboardingScreen] {
        [branch, .goal, .routines, .speedwork, .lessons]
    }

    /// The first screen in the intake sequence whose required fields are NOT all
    /// confirmed. Implements the skip-ahead loop (spec §4.3): screens whose fields
    /// were already volunteered are skipped. Returns nil when every intake screen is
    /// satisfied (→ the caller should be in plan-building/reveal).
    static func firstUnsatisfied(
        branch: OnboardingScreen,
        confirmed: [String]
    ) -> OnboardingScreen? {
        let confirmedSet = Set(confirmed)
        for screen in intakeSequence(branch: branch) {
            let satisfied = requiredFields(for: screen).allSatisfy { confirmedSet.contains($0) }
            if !satisfied { return screen }
        }
        return nil
    }

    /// Whether a screen's gate is satisfied by the current confirmed set.
    static func isSatisfied(_ screen: OnboardingScreen, confirmed: [String]) -> Bool {
        let confirmedSet = Set(confirmed)
        return requiredFields(for: screen).allSatisfy { confirmedSet.contains($0) }
    }
}
