//
//  RunsAPI.swift
//  Stridewell
//

import Foundation

extension APIClient {

    /// Fetch the N most recent runs. Defaults to 3.
    func recentRuns(limit: Int = 3) async -> ApiResult<RecentRunsResponse> {
        await get(path: "\(APIEndpoints.runsRecent)?limit=\(limit)")
    }
}
