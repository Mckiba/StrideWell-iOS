//
//  APIEndpoints.swift
//  Stridewell
//

import Foundation

/// Path constants for all API endpoints.
/// Each milestone adds its constants here — no magic strings in call sites.
enum APIEndpoints {

    // MARK: Auth (M2)
    static let login             = "/auth/login"
    static let me                = "/auth/me"

    // MARK: Onboarding (M3–M7)
    static let onboardingStart   = "/onboarding/start"
    static let onboardingStatus  = "/onboarding/status"
    static let onboardingMessage = "/onboarding/message"
    static let onboardingConfirm = "/onboarding/confirm-plan"

    // MARK: Plan (M8–M9)
    static let planToday         = "/plan/today"
    static let planWeek          = "/plan/week"

    // MARK: Chat (M11)
    static let chatMessage       = "/chat/message"

    // MARK: Reflection (M10)
    static let reflection        = "/reflection"

    // MARK: Strava OAuth (M4, M13)
    static let stravaConnect     = "/oauth/strava/connect"
    static let stravaDisconnect  = "/oauth/strava/disconnect"

    // MARK: Notifications (M15)
    static let notificationsRegister = "/notifications/register"
}
