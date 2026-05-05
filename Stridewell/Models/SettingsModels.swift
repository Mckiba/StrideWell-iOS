//
//  SettingsModels.swift
//  Stridewell
//
//  Response types for settings-related API calls.
//

import Foundation

/// GET /auth/strava-status
struct StravaStatusResponse: Decodable {
    let connected: Bool
    let expires_at: String?
    let scope: String?
}

/// POST /oauth/strava/disconnect
struct StravaDisconnectResponse: Decodable {
    let connected: Bool
}

/// Sentinel type for endpoints that return 204 No Content.
struct EmptyResponse: Decodable {
    init() {}
}

// MARK: - Proactive Coaching Preferences (V2 Phase 5)

struct ProactivePreferencesRequest: Encodable {
    let enabled: Bool
    let categories_enabled: ProactiveCategoriesEnabled
    let quiet_hours: ProactiveQuietHours
    let timezone: String
}

struct ProactiveCategoriesEnabled: Encodable {
    let training_milestone: Bool
    let training_concern: Bool
    let upcoming_event: Bool
    let reengagement: Bool
    let plan_followup: Bool
}

struct ProactiveQuietHours: Encodable {
    let enabled: Bool
    let start_local: String
    let end_local: String
}

struct ProactivePreferencesStoredResponse: Decodable {
    let stored: Bool
}
