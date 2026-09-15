//
//  ActivitySummaryStore.swift
//  Stridewell
//
//  Activities overview store: the selected range and period, the period's
//  summary (totals + chart buckets), and the period's paginated run list.
//  Summaries are cached per range+period so switching back is instant.
//

import Foundation
import Observation

@Observable
final class ActivitySummaryStore {

    struct Section: Identifiable {
        let title: String
        let runs: [Run]
        var id: String { title }
    }

    // MARK: - Selection

    private(set) var range: ActivityRange = .week
    private(set) var periodStart: Date = DateUtils.periodStart(for: .week, containing: Date())

    // MARK: - State

    /// Loading until the first summary arrives; empty when the user has no runs at all.
    var state: LoadableState<Void> = .loading

    /// Summary for the selected period, or the previous one while a new one loads.
    var summary: RunSummaryResponse?

    /// True while the selected period's summary is being fetched.
    var isLoadingSummary = false

    /// Runs in the selected period, newest first, across loaded pages.
    var runs: [Run] = []

    /// Completed/modified plan days keyed by their linked run id.
    var planDaysByRunId: [String: PlanDay] = [:]

    var hasMore = false
    var isLoadingRuns = false
    var isLoadingMore = false

    // MARK: - Private

    private let pageSize = 20
    private var summaryCache: [String: RunSummaryResponse] = [:]
    private var runsKey: String?

    // MARK: - Derived

    /// Identifies the selected range and period; a change triggers a reload.
    var selectionKey: String {
        range == .all ? "all" : "\(range.rawValue)-\(DateUtils.format(periodStart))"
    }

    /// Selectable period starts for the dropdown, newest first.
    var periodStarts: [Date] {
        DateUtils.periodStarts(for: range, back: summary?.first_run_date.flatMap { DateUtils.parse($0) })
    }

    // MARK: - Selection

    func select(range newRange: ActivityRange) {
        guard newRange != range else { return }
        range = newRange
        periodStart = DateUtils.periodStart(for: newRange, containing: Date())
        clearRuns()
    }

    func select(periodStart start: Date) {
        guard start != periodStart else { return }
        periodStart = start
        clearRuns()
    }

    // MARK: - Load

    /// Loads the summary and first page of runs for the current selection.
    /// Serves cached summaries unless `force` is set.
    func load(apiClient: APIClient, force: Bool = false) async {
        let key = selectionKey
        if force {
            summaryCache[key] = nil
            runsKey = nil
        }

        if let cached = summaryCache[key] {
            summary = cached
            isLoadingSummary = false
        } else {
            isLoadingSummary = true
            let result = await apiClient.runSummary(range: range, start: periodStart)
            guard key == selectionKey else { return }
            isLoadingSummary = false

            switch result {
            case .success(let response):
                summaryCache[key] = response
                summary = response
            case .failure(_, let message):
                state = .error(message)
                return
            }
        }

        guard let summary else { return }
        guard summary.first_run_date != nil else {
            state = .empty
            return
        }
        state = .loaded

        guard runsKey != key, let window = Self.listWindow(summary) else { return }
        isLoadingRuns = true
        let result = await apiClient.activities(from: window.from, to: window.to, limit: pageSize, offset: 0)
        guard key == selectionKey else { return }
        isLoadingRuns = false
        runsKey = key

        switch result {
        case .success(let response):
            runs = response.runs
            planDaysByRunId = Self.index(response.plan_days)
            hasMore = response.hasMore ?? false
        case .failure:
            clearRuns()
        }
    }

    /// Appends the next page. No-op if already loading or no more pages exist.
    func loadMore(apiClient: APIClient) async {
        guard hasMore, !isLoadingMore, let summary, let window = Self.listWindow(summary) else { return }
        let key = selectionKey
        isLoadingMore = true
        defer { isLoadingMore = false }

        let result = await apiClient.activities(from: window.from, to: window.to, limit: pageSize, offset: runs.count)
        guard key == selectionKey, case .success(let response) = result else { return }
        runs.append(contentsOf: response.runs)
        planDaysByRunId.merge(Self.index(response.plan_days)) { _, new in new }
        hasMore = response.hasMore ?? false
    }

    /// The run behind a single-run chart bucket, from the loaded list or a one-row fetch.
    func run(for bucket: RunSummaryBucket, apiClient: APIClient) async -> Run? {
        guard bucket.run_count == 1, let runId = bucket.run_id else { return nil }
        if let run = runs.first(where: { $0.id == runId }) { return run }

        let bucketRange = summary.flatMap { ActivityRange(rawValue: $0.range) } ?? range
        guard let window = DateUtils.bucketWindow(for: bucketRange, key: bucket.key) else { return nil }
        let result = await apiClient.activities(from: window.from, to: window.to, limit: 1, offset: 0)
        guard case .success(let response) = result else { return nil }
        return response.runs.first { $0.id == runId }
    }

    // MARK: - Sections

    /// Groups runs for display. The current period splits into today's date and
    /// "Earlier This <Period>"; a past period is one section titled with its label.
    func sections(today: Date = Date()) -> [Section] {
        guard !runs.isEmpty else { return [] }

        let isCurrent = range == .all || periodStart == DateUtils.periodStart(for: range, containing: today)
        guard isCurrent else {
            return [Section(title: DateUtils.periodLabel(for: range, start: periodStart, today: today), runs: runs)]
        }

        let calendar = Calendar.current
        let isToday: (Run) -> Bool = { run in
            DateUtils.parseISO8601(run.start_time).map { calendar.isDate($0, inSameDayAs: today) } ?? false
        }
        let todayRuns = runs.filter(isToday)
        let earlierRuns = runs.filter { !isToday($0) }

        var sections: [Section] = []
        if !todayRuns.isEmpty {
            sections.append(Section(title: DateUtils.sectionDayLabel(today), runs: todayRuns))
        }
        if !earlierRuns.isEmpty {
            sections.append(Section(title: DateUtils.earlierLabel(for: range), runs: earlierRuns))
        }
        return sections
    }

    // MARK: - Reset

    func reset() {
        range = .week
        periodStart = DateUtils.periodStart(for: .week, containing: Date())
        state = .loading
        summary = nil
        isLoadingSummary = false
        summaryCache = [:]
        clearRuns()
    }

    // MARK: - Helpers

    private func clearRuns() {
        runs = []
        planDaysByRunId = [:]
        hasMore = false
        isLoadingRuns = false
        isLoadingMore = false
        runsKey = nil
    }

    /// Inclusive first and last day of a summary's [start, end) period.
    private static func listWindow(_ summary: RunSummaryResponse) -> (from: Date, to: Date)? {
        guard let from = DateUtils.parse(summary.start),
              let end = DateUtils.parse(summary.end),
              let to = Calendar.current.date(byAdding: .day, value: -1, to: end) else { return nil }
        return (from, to)
    }

    private static func index(_ planDays: [PlanDay]?) -> [String: PlanDay] {
        Dictionary(
            (planDays ?? []).compactMap { day in day.runId.map { ($0, day) } },
            uniquingKeysWith: { first, _ in first }
        )
    }
}
