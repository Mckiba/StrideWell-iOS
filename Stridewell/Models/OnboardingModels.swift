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

// MARK: - Interview message types (M4)

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
}

// onboarding_state field inside POST /onboarding/message response
struct OnboardingMessageOnboardingState: Codable {
    let status: OnboardingStatus
    let intake_complete: Bool
    let plan_building: Bool
    let first_plan_version_id: String?
}

// Full POST /onboarding/message response
struct OnboardingMessageResponse: Codable {
    let conversation_id: String
    let reply: InterviewMessage
    let onboarding_state: OnboardingMessageOnboardingState
}
