//
//  APIEndpoints.swift
//  Stridewell
//

import Foundation

/// Path constants for all API endpoints.
/// Each milestone adds its constants here — no magic strings in call sites.
enum APIEndpoints {

    // MARK: Auth (M2)
    static let register          = "/auth/register"
    static let login             = "/auth/login"
    static let me                = "/auth/me"

    // MARK: Onboarding (M3–M7)
    static let onboardingStart   = "/onboarding/start"
    static let onboardingStatus  = "/onboarding/status"
    static let onboardingMessage = "/onboarding/message"
    static let onboardingConfirm = "/onboarding/confirm-plan"

    // MARK: Plan (M6–M11)
    static let planToday         = "/plan/today"
    static let planWeek          = "/plan/week"
    static let planVersion       = "/plan/version"  // GET /plan/version/:id?weeks=N
    static let latestDecision    = "/plan/latest-decision"
    static let goalSummary       = "/plan/goal-summary"

    // MARK: Runs (M7, Heatmap)
    static let runsRecent        = "/runs/recent"
    static let runsHeatmap       = "/runs/heatmap"

    // MARK: Chat (M10)
    static let chatMessage       = "/chat/message"

    // MARK: Reflection (M9)
    static let reflection        = "/reflection"

    // MARK: Strava OAuth (M3, M12)
    static let stravaConnect     = "/oauth/strava/connect"
    static let stravaDisconnect  = "/oauth/strava/disconnect"
    static let stravaStatus      = "/auth/strava-status"

    // MARK: Account (M12)
    static let deleteAccount         = "/auth/account"

    // MARK: Notifications (M15)
    static let notificationsRegister = "/notifications/register"
}
