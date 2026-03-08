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
