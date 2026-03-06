//
//  PlanStore.swift
//  Stridewell
//
//  Plan state management — tracks current plan version, today's workout,
//  and plan-change detection via lastSeenPlanVersionId (UserDefaults).
//

import Foundation

@Observable
final class PlanStore {

    // MARK: - State

    /// plan_version_id from the most recent /plan/week fetch.
    private(set) var currentPlanVersionId: String? = nil

    /// plan_version_id the user last acknowledged (persisted to UserDefaults).
    /// Only updated by markPlanChangeSeen().
    private(set) var lastSeenPlanVersionId: String? = nil

    /// Today's PlanDay from GET /plan/today.
    private(set) var todayPlanDay: PlanDay? = nil

    /// Current week data from GET /plan/week (used by HomeScreen).
    private(set) var currentWeek: PlanWeekResponse? = nil

    /// In-memory week cache keyed by start_date ("YYYY-MM-DD").
    /// Used by PlanScreen for instant week navigation.
    private(set) var weekCache: [String: PlanWeekResponse] = [:]

    /// True when the plan version has changed since the user last viewed it.
    var hasPlanChanged: Bool {
        guard let current = currentPlanVersionId,
              let seen = lastSeenPlanVersionId else {
            return false
        }
        return current != seen
    }

    // MARK: - Persistence

    private static let lastSeenKey = "PlanStore.lastSeenPlanVersionId"

    // MARK: - Init

    init() {
        lastSeenPlanVersionId = UserDefaults.standard.string(forKey: Self.lastSeenKey)
    }

    // MARK: - Actions

    func setTodayPlanDay(_ day: PlanDay) {
        todayPlanDay = day
    }

    func setWeekData(_ week: PlanWeekResponse) {
        currentWeek = week
        currentPlanVersionId = week.plan_version_id

        // First time seeing any plan (fresh install after onboarding) —
        // auto-sync so the banner doesn't show for the very first plan.
        if lastSeenPlanVersionId == nil {
            markPlanChangeSeen()
        }
    }

    // MARK: - Week Cache (M8)

    /// Returns a cached week if available for the given start date.
    func cachedWeek(for startDate: String) -> PlanWeekResponse? {
        weekCache[startDate]
    }

    /// Stores a fetched week in the cache and updates plan version tracking.
    func cacheWeek(_ week: PlanWeekResponse) {
        weekCache[week.start_date] = week
        currentPlanVersionId = week.plan_version_id

        if lastSeenPlanVersionId == nil {
            markPlanChangeSeen()
        }
    }

    /// Called when the user dismisses PlanChangeScreen (M11).
    func markPlanChangeSeen() {
        lastSeenPlanVersionId = currentPlanVersionId
        UserDefaults.standard.set(currentPlanVersionId, forKey: Self.lastSeenKey)
    }

    /// Reset on sign-out.
    func reset() {
        currentPlanVersionId = nil
        lastSeenPlanVersionId = nil
        todayPlanDay = nil
        currentWeek = nil
        weekCache = [:]
        UserDefaults.standard.removeObject(forKey: Self.lastSeenKey)
    }
}
