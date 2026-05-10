//
//  PlanStore.swift
//  Stridewell
//
//  Plan state management — tracks current plan version, today's workout,
//  plan-change detection via lastSeenPlanVersionId (UserDefaults), and
//  M13 offline cache (persists plan data across restarts via UserDefaults).
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

    /// Goal + plan progress data from GET /plan/goal-summary. Used by GoalCardView.
    private(set) var goalSummary: GoalSummary? = nil

    /// Current week data from GET /plan/week (used by HomeScreen).
    private(set) var currentWeek: PlanWeekResponse? = nil

    /// In-memory week cache keyed by start_date ("YYYY-MM-DD").
    /// Pre-populated from UserDefaults at init (M13) so cached data
    /// survives app restarts. Used by PlanScreen for instant week navigation.
    private(set) var weekCache: [String: PlanWeekResponse] = [:]

    /// Cached recent runs from the home feed — persisted to UserDefaults.
    /// Served offline when the /runs/recent call fails.
    private(set) var cachedRecentRuns: [Run] = []

    // MARK: - Offline State

    /// Last successfully fetched PlanDay, persisted to UserDefaults.
    /// Served to callers via serveCachedTodayOffline() when network is unavailable.
    private(set) var cachedToday: PlanDay? = nil

    /// Last successful fetch timestamps per cache key ("today" or "YYYY-MM-DD").
    /// Persisted to UserDefaults; used by the offline banner to show freshness.
    private(set) var lastFetchTime: [String: Date] = [:]

    /// True when the plan version has changed since the user last viewed it.
    var hasPlanChanged: Bool {
        guard let current = currentPlanVersionId,
              let seen = lastSeenPlanVersionId else {
            return false
        }
        return current != seen
    }

    // MARK: - Persistence Keys

    private static let lastSeenKey        = "PlanStore.lastSeenPlanVersionId"
    private static let cachedTodayKey     = "PlanStore.cachedToday"
    private static let weekCacheKey       = "PlanStore.weekCache"
    private static let lastFetchTimeKey   = "PlanStore.lastFetchTime"
    private static let cachedGoalKey      = "PlanStore.cachedGoal"
    private static let cachedRecentRunsKey = "PlanStore.cachedRecentRuns"

    // MARK: - Init

    init() {
        lastSeenPlanVersionId = UserDefaults.standard.string(forKey: Self.lastSeenKey)
        loadPersistedCache()
    }

    private func loadPersistedCache() {
        if let data = UserDefaults.standard.data(forKey: Self.cachedTodayKey),
           let day = try? JSONDecoder().decode(PlanDay.self, from: data) {
            cachedToday = day
        }
        if let data = UserDefaults.standard.data(forKey: Self.weekCacheKey),
           let cache = try? JSONDecoder().decode([String: PlanWeekResponse].self, from: data) {
            weekCache = cache  // pre-populates in-memory cache for offline serving
        }
        if let data = UserDefaults.standard.data(forKey: Self.lastFetchTimeKey),
           let times = try? JSONDecoder().decode([String: Date].self, from: data) {
            lastFetchTime = times
        }

        // Goal summary
        if let data = UserDefaults.standard.data(forKey: Self.cachedGoalKey),
           let goal = try? JSONDecoder().decode(GoalSummary.self, from: data) {
            goalSummary = goal
        }

        // Recent runs (HomeScreen home feed)
        if let data = UserDefaults.standard.data(forKey: Self.cachedRecentRunsKey),
           let runs = try? JSONDecoder().decode([Run].self, from: data) {
            cachedRecentRuns = runs
        }

        // Pre-populate currentWeek so HomeScreen "Next Workout" works offline
        let thisWeekStart = DateUtils.format(DateUtils.mondayOfWeek(containing: Date()))
        if let thisWeek = weekCache[thisWeekStart] {
            currentWeek = thisWeek
            currentPlanVersionId = thisWeek.plan_version_id
        }
    }

    // MARK: - Actions

    func setGoalSummary(_ summary: GoalSummary) {
        goalSummary = summary
        if let data = try? JSONEncoder().encode(summary) {
            UserDefaults.standard.set(data, forKey: Self.cachedGoalKey)
        }
    }

    func setRecentRuns(_ runs: [Run]) {
        cachedRecentRuns = runs
        if let data = try? JSONEncoder().encode(runs) {
            UserDefaults.standard.set(data, forKey: Self.cachedRecentRunsKey)
        }
    }

    func setTodayPlanDay(_ day: PlanDay) {
        todayPlanDay = day
        // Persist to disk for offline serving
        cachedToday = day
        lastFetchTime["today"] = Date()
        persistCachedToday()
        persistLastFetchTime()
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

    // MARK: - Week Cache

    /// Returns a cached week if available for the given start date.
    /// Checks in-memory cache, which is pre-populated from UserDefaults at init.
    func cachedWeek(for startDate: String) -> PlanWeekResponse? {
        weekCache[startDate]
    }

    /// Stores a fetched week in the cache, persists to disk, and updates plan version tracking.
    /// Evicts entries beyond the 8 most-recently-fetched weeks to bound memory and disk usage.
    func cacheWeek(_ week: PlanWeekResponse) {
        weekCache[week.start_date] = week
        currentPlanVersionId = week.plan_version_id
        lastFetchTime[week.start_date] = Date()

        // Keep only the 8 most recently fetched weeks (by fetch time, not calendar order)
        if weekCache.count > 8 {
            let oldest = lastFetchTime
                .sorted { $0.value < $1.value }
                .prefix(weekCache.count - 8)
                .map(\.key)
            for key in oldest {
                weekCache.removeValue(forKey: key)
                lastFetchTime.removeValue(forKey: key)
            }
        }

        persistWeekCache()
        persistLastFetchTime()

        if lastSeenPlanVersionId == nil {
            markPlanChangeSeen()
        }
    }

    // MARK: - Offline Fallback

    /// Serves the last cached today-plan when the network is unavailable.
    /// Populates `todayPlanDay` from cache.
    /// Returns nil if no persistent cache exists (first launch / after sign-out).
    func serveCachedTodayOffline() -> PlanDay? {
        guard let cached = cachedToday else { return nil }
        todayPlanDay = cached
        return cached
    }

    /// Serves a persisted week when the network is unavailable.
    /// Returns nil if no cache exists for this startDate.
    func serveCachedWeekOffline(for startDate: String) -> PlanWeekResponse? {
        weekCache[startDate]
    }

    /// Last successful fetch timestamp for a given cache key.
    /// Keys: "today" for /plan/today, or "YYYY-MM-DD" for /plan/week.
    func lastFetched(for key: String) -> Date? {
        lastFetchTime[key]
    }

    // MARK: - Plan Change

    /// Called from the foreground push handler when a plan_change push arrives.
    /// Updates the version ID so the plan change banner surfaces on HomeScreen.
    func setCurrentPlanVersionId(_ id: String) {
        currentPlanVersionId = id
    }

    /// Called when the user dismisses PlanChangeScreen.
    func markPlanChangeSeen() {
        lastSeenPlanVersionId = currentPlanVersionId
        UserDefaults.standard.set(currentPlanVersionId, forKey: Self.lastSeenKey)
    }

    // MARK: - Reset (sign-out / account deletion)

    func reset() {
        currentPlanVersionId = nil
        lastSeenPlanVersionId = nil
        todayPlanDay = nil
        goalSummary = nil
        currentWeek = nil
        weekCache = [:]
        cachedToday = nil
        cachedRecentRuns = []
        lastFetchTime = [:]
        UserDefaults.standard.removeObject(forKey: Self.lastSeenKey)
        UserDefaults.standard.removeObject(forKey: Self.cachedTodayKey)
        UserDefaults.standard.removeObject(forKey: Self.weekCacheKey)
        UserDefaults.standard.removeObject(forKey: Self.lastFetchTimeKey)
        UserDefaults.standard.removeObject(forKey: Self.cachedGoalKey)
        UserDefaults.standard.removeObject(forKey: Self.cachedRecentRunsKey)
    }

    // MARK: - Private Persistence

    private func persistCachedToday() {
        guard let data = try? JSONEncoder().encode(cachedToday) else { return }
        UserDefaults.standard.set(data, forKey: Self.cachedTodayKey)
    }

    private func persistWeekCache() {
        guard let data = try? JSONEncoder().encode(weekCache) else { return }
        UserDefaults.standard.set(data, forKey: Self.weekCacheKey)
    }

    private func persistLastFetchTime() {
        guard let data = try? JSONEncoder().encode(lastFetchTime) else { return }
        UserDefaults.standard.set(data, forKey: Self.lastFetchTimeKey)
    }
}
