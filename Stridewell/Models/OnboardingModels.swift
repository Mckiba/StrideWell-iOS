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
    let conversation_id: String?      // present on resume; used by IntakeInterviewScreen
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
