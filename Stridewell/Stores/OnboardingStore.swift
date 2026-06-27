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

    // Drives which guided screen shows next and pre-fills controls when returning.
    private(set) var confirmedFields: [String] = []
    private(set) var partialIntake: PartialIntake? = nil
    private(set) var historySummary: StravaHistorySummary? = nil

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
        // Only overwrite when present, so a response that omits these leaves them as-is.
        if let confirmed = state.confirmed_fields { confirmedFields = confirmed }
        if let partial = state.partial_intake { partialIntake = partial }
        if let summary = state.history_summary { historySummary = summary }
        if isComplete { persistCompletion() }
    }

    /// Store the confirmed fields returned by a message reply.
    func applyConfirmedFields(_ fields: [String]?) {
        if let fields { confirmedFields = fields }
    }

    /// Called after the plan is confirmed. Flips `isComplete`, so RootView shows the
    /// main tab bar.
    func markComplete() {
        status = .complete
        persistCompletion()
    }

    /// Called after onboarding is skipped. `skipped` counts as complete, so the app
    /// moves on to the main tab bar with a default plan.
    func markSkipped() {
        status = .skipped
        persistCompletion()
    }

    func reset() {
        status             = .pending
        stravaConnected    = false
        intakeComplete     = false
        firstPlanVersionId = nil
        conversationId     = nil
        confirmedFields    = []
        partialIntake      = nil
        historySummary     = nil
        UserDefaults.standard.removeObject(forKey: Self.isCompleteKey)
    }

    // MARK: - Private

    private func persistCompletion() {
        UserDefaults.standard.set(true, forKey: Self.isCompleteKey)
    }
}
