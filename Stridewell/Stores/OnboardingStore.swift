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

    // V2 guided flow — advancement + resume state.
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
        // V2 hydration (nil on a V1 backend → leave existing state untouched).
        if let confirmed = state.confirmed_fields { confirmedFields = confirmed }
        if let partial = state.partial_intake { partialIntake = partial }
        if let summary = state.history_summary { historySummary = summary }
        if isComplete { persistCompletion() }
    }

    /// Merge the latest `confirmed_fields` from a POST /onboarding/message reply.
    func applyConfirmedFields(_ fields: [String]?) {
        if let fields { confirmedFields = fields }
    }

    /// Called after POST /onboarding/confirm-plan succeeds.
    /// Flips isComplete → RootView re-routes to the main tab bar automatically.
    func markComplete() {
        status = .complete
        persistCompletion()
    }

    /// Called after POST /onboarding/skip succeeds. `skipped` is terminal in the
    /// current data model (RootView + launch routing treat it as complete), so this
    /// flips isComplete and the app proceeds to the main tab bar with a default plan.
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
