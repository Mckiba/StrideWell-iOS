//
//  DecisionAPI.swift
//  Stridewell
//
//  M11: Fetch latest decision record for plan change screen.
//

import Foundation

extension APIClient {

    /// GET /plan/latest-decision — fetch the most recent decision record.
    func latestDecision() async -> ApiResult<LatestDecisionResponse> {
        await get(path: APIEndpoints.latestDecision)
    }
}
