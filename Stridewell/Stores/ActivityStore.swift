//
//  ActivityStore.swift
//  Stridewell
//
//  Tracks the activity banner state — whether a new synced run needs to be
//  surfaced to the user on HomeScreen.
//
//  lastSyncedRunId / lastSyncedRunSummary: persisted to UserDefaults so the
//  banner survives app relaunches until explicitly dismissed.
//
//  lastSeenRunId: persisted to UserDefaults — updated only when the user
//  explicitly taps or dismisses the activity banner.
//

import Foundation
import Observation

@Observable
final class ActivityStore {

    // MARK: - State

    /// Set from push payload on activity sync. Persisted so the banner
    /// survives relaunches until the user explicitly dismisses it.
    var lastSyncedRunId: String? {
        didSet { UserDefaults.standard.set(lastSyncedRunId, forKey: Self.syncedKey) }
    }

    /// Push body text, e.g. "4.2mi run @ 8:30/mi pace". Persisted alongside lastSyncedRunId.
    var lastSyncedRunSummary: String? {
        didSet { UserDefaults.standard.set(lastSyncedRunSummary, forKey: Self.summaryKey) }
    }

    /// Last run the user acknowledged. Persisted across launches.
    private(set) var lastSeenRunId: String? {
        didSet { UserDefaults.standard.set(lastSeenRunId, forKey: Self.seenKey) }
    }

    // MARK: - Computed

    /// True when a new run has been synced that the user hasn't yet acknowledged.
    var showActivityBanner: Bool {
        guard let synced = lastSyncedRunId else { return false }
        return synced != lastSeenRunId
    }

    // MARK: - Init

    init() {
        self.lastSyncedRunId     = UserDefaults.standard.string(forKey: Self.syncedKey)
        self.lastSyncedRunSummary = UserDefaults.standard.string(forKey: Self.summaryKey)
        self.lastSeenRunId       = UserDefaults.standard.string(forKey: Self.seenKey)
    }

    // MARK: - Actions

    /// Called when a foreground push arrives with a new run_id.
    func setLastSyncedRun(runId: String, summary: String) {
        lastSyncedRunId = runId
        lastSyncedRunSummary = summary
    }

    /// Called on banner tap or explicit dismiss — marks the current run as seen.
    func dismissBanner() {
        lastSeenRunId = lastSyncedRunId
    }

    /// Called on sign-out — clears all state.
    func reset() {
        lastSyncedRunId = nil
        lastSyncedRunSummary = nil
        lastSeenRunId = nil
        UserDefaults.standard.removeObject(forKey: Self.syncedKey)
        UserDefaults.standard.removeObject(forKey: Self.summaryKey)
        UserDefaults.standard.removeObject(forKey: Self.seenKey)
    }

    // MARK: - Private

    private static let syncedKey  = "activityStore.lastSyncedRunId"
    private static let summaryKey = "activityStore.lastSyncedRunSummary"
    private static let seenKey    = "activityStore.lastSeenRunId"
}
