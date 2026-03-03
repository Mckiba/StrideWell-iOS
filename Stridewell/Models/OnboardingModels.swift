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

struct OnboardingState: Codable {
    let status: OnboardingStatus
    let strava_connected: Bool
    let intake_complete: Bool
    let first_plan_version_id: String?
}
