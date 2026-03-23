//
//  ActivitiesStore.swift
//  Stridewell
//
//  Paginated activity list store.
//  - refresh() resets to page 0 and replaces the list (called on first load,
//    search change, and date filter change).
//  - loadMore() appends the next page (called when the scroll sentinel appears).
//  Search and date filtering are server-side so results are always complete.
//

import Foundation
import Observation

@Observable
final class ActivitiesStore {

    // MARK: - State

    /// Accumulated runs across all loaded pages.
    var runs: [Run] = []

    /// Controls the initial loading / error / empty / loaded states.
    var state: LoadableState<Void> = .loading

    /// True while a loadMore fetch is in flight (shows a bottom spinner).
    var isLoadingMore = false

    /// False once the server returns fewer rows than the page size.
    var hasMore = false

    // MARK: - Private

    private let pageSize = 20
    private var currentOffset = 0

    // MARK: - Refresh (reset to page 0)

    /// Resets the list and fetches the first page with the given filters.
    /// Call when the screen first appears, or whenever search/date changes.
    func refresh(search: String, date: Date?, apiClient: APIClient) async {
        currentOffset = 0
        runs = []
        hasMore = false
        state = .loading

        let result = await apiClient.activities(limit: pageSize, offset: 0, search: search, date: date)
        switch result {
        case .success(let response):
            runs = response.runs
            hasMore = response.hasMore ?? false
            currentOffset = response.runs.count
            // Only show the empty state when there are genuinely no runs (no filters active).
            let noFilters = search.isEmpty && date == nil
            state = runs.isEmpty && noFilters ? .empty : .loaded
        case .failure(_, let message):
            state = .error(message)
        }
    }

    // MARK: - Load More (next page)

    /// Appends the next page. No-op if already loading or no more pages exist.
    func loadMore(search: String, date: Date?, apiClient: APIClient) async {
        guard hasMore, !isLoadingMore, case .loaded = state else { return }
        isLoadingMore = true
        defer { isLoadingMore = false }

        let result = await apiClient.activities(limit: pageSize, offset: currentOffset, search: search, date: date)
        if case .success(let response) = result {
            runs.append(contentsOf: response.runs)
            hasMore = response.hasMore ?? false
            currentOffset = runs.count
        }
    }

    // MARK: - Reset

    func reset() {
        runs = []
        state = .loading
        hasMore = false
        currentOffset = 0
    }
}
