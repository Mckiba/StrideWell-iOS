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
    private(set) var conversationId: String? = nil

    var isComplete: Bool { status == .complete || status == .skipped }

    // MARK: - Persistence

    /// Persisted so RootView routes directly to the main tab bar on cold
    /// starts when the device is offline — no network call required.
    private static let isCompleteKey = "OnboardingStore.isComplete"

    // MARK: - Init

    init() {
        if UserDefaults.standard.bool(forKey: Self.isCompleteKey) {
            status = .complete
        }
    }

    // MARK: - Actions

    func onStarted(conversationId: String, status: OnboardingStatus, stravaConnected: Bool) {
        self.conversationId = conversationId
        self.status = status
        self.stravaConnected = stravaConnected
    }

    func stravaDidConnect() {
        self.stravaConnected = true
    }

    func update(from state: OnboardingState) {
        status             = state.status
        stravaConnected    = state.strava_connected
        intakeComplete     = state.intake_complete
        firstPlanVersionId = state.first_plan_version_id
        if let cid = state.conversation_id { conversationId = cid }
        if isComplete { persistCompletion() }
    }

    /// Called after POST /onboarding/confirm-plan succeeds.
    /// Flips isComplete → RootView re-routes to the main tab bar automatically.
    func markComplete() {
        status = .complete
        persistCompletion()
    }

    func reset() {
        status             = .pending
        stravaConnected    = false
        intakeComplete     = false
        firstPlanVersionId = nil
        conversationId     = nil
        UserDefaults.standard.removeObject(forKey: Self.isCompleteKey)
    }

    // MARK: - Private

    private func persistCompletion() {
        UserDefaults.standard.set(true, forKey: Self.isCompleteKey)
    }
}
