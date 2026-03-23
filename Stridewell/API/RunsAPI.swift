//
//  RunsAPI.swift
//  Stridewell
//

import Foundation

extension APIClient {

    /// Fetch the N most recent runs. Defaults to 3. Used by HomeScreen.
    func recentRuns(limit: Int = 3) async -> ApiResult<RecentRunsResponse> {
        await get(path: "\(APIEndpoints.runsRecent)?limit=\(limit)")
    }

    /// Fetch all synced runs within the 7-day week starting on `monday`.
    /// Used by PlanScreen weekly overview card.
    func runsForWeek(monday: Date) async -> ApiResult<RecentRunsResponse> {
        let from = DateUtils.format(monday)
        let to   = DateUtils.format(Calendar.current.date(byAdding: .day, value: 6, to: monday)!)
        return await get(path: "\(APIEndpoints.runsRecent)?limit=14&date_from=\(from)&date_to=\(to)")
    }

    /// Paginated run list with optional server-side search and date filter.
    /// Used by ActivitiesScreen.
    func activities(limit: Int, offset: Int, search: String, date: Date?) async -> ApiResult<RecentRunsResponse> {
        var path = "\(APIEndpoints.runsRecent)?limit=\(limit)&offset=\(offset)"
        if !search.isEmpty, let encoded = search.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) {
            path += "&search=\(encoded)"
        }
        if let date {
            path += "&date=\(DateUtils.format(date))"
        }
        return await get(path: path)
    }
}
