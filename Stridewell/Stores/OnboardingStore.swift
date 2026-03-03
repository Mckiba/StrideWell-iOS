//
//  OnboardingStore.swift
//  Stridewell
//

import Foundation
import Observation

@Observable
final class OnboardingStore {

    private(set) var status: OnboardingStatus = .pending
    private(set) var stravaConnected: Bool = false
    private(set) var intakeComplete: Bool = false
    private(set) var firstPlanVersionId: String? = nil

    var isComplete: Bool { status == .complete }

    func update(from state: OnboardingState) {
        status            = state.status
        stravaConnected   = state.strava_connected
        intakeComplete    = state.intake_complete
        firstPlanVersionId = state.first_plan_version_id
    }

    func reset() {
        status            = .pending
        stravaConnected   = false
        intakeComplete    = false
        firstPlanVersionId = nil
    }
}
