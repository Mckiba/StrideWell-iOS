//
//  OnboardingFlow.swift
//  Stridewell
//
//  Screen ordering and advancement for guided onboarding. The next screen is chosen
//  by which intake fields are confirmed, never by message count.
//

import Foundation

/// Screens in the guided onboarding flow, in order. `historyConfirm` and
/// `manualBaseline` are mutually exclusive: which baseline screen is shown depends
/// on whether usable Strava history exists.
enum OnboardingScreen: Hashable {
    case integrations     // connect data sources
    case historyConfirm   // confirm the baseline read from Strava
    case manualBaseline   // enter the baseline by hand
    case goal
    case routines
    case speedwork
    case lessons
    case planBuilding     // generating the first plan
    case planReveal       // review and confirm the plan
}

enum OnboardingFlow {

    /// The `screen_context` sent with each message on this screen. nil for screens
    /// that have no conversation (connect, plan building, plan reveal).
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

    /// Intake fields that must be confirmed before leaving this screen. The screen is
    /// satisfied once all of them appear in `confirmed_fields`.
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
            return []
        }
    }

    /// Chooses the baseline screen: confirm-from-Strava when connected history is
    /// usable, otherwise manual entry. Recomputed on each call rather than stored.
    static func baselineBranch(
        stravaConnected: Bool,
        historySummary: StravaHistorySummary?
    ) -> OnboardingScreen {
        guard stravaConnected, let summary = historySummary else { return .manualBaseline }
        if summary.inferred_training_phase == "insufficient_data" { return .manualBaseline }
        return .historyConfirm
    }

    /// The intake screens in order, starting from the chosen baseline screen. Connect,
    /// plan building, and plan reveal sit outside this sequence.
    static func intakeSequence(branch: OnboardingScreen) -> [OnboardingScreen] {
        [branch, .goal, .routines, .speedwork, .lessons]
    }

    /// The first intake screen whose required fields aren't all confirmed. Screens
    /// whose fields were already answered are skipped. Returns nil once every intake
    /// screen is satisfied.
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

    /// Whether the screen's required fields are all present in the confirmed set.
    static func isSatisfied(_ screen: OnboardingScreen, confirmed: [String]) -> Bool {
        let confirmedSet = Set(confirmed)
        return requiredFields(for: screen).allSatisfy { confirmedSet.contains($0) }
    }
}
