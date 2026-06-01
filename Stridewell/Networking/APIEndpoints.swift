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
    static let appleSignIn       = "/auth/apple"
    static let googleSignIn      = "/auth/google"
    static let refreshSession    = "/auth/refresh"
    static let forgotPassword    = "/auth/forgot-password"
    static let resetPassword     = "/auth/reset-password"

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

    // MARK: Runs (M7, Heatmap, Detail)
    static let runsRecent        = "/runs/recent"
    static let runsHeatmap       = "/runs/heatmap"
    static let runDetail         = "/runs"          // GET /runs/:runId
    static let runAnalysis       = "/runs"          // GET /runs/:runId/analysis

    // MARK: Analysis / Profile (V2 Phase 2)
    static let analysisWeekly    = "/analysis/weekly"
    static let profileFitness    = "/profile/fitness"
    static let proactivePreferences = "/profile/proactive-preferences"

    // MARK: Chat (M10, M14)
    static let chatMessage       = "/chat/message"
    static let chatHistory       = "/chat/history"

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

    // MARK: Home Cards (Weather)
    static let homeCards         = "/home/cards"
}
