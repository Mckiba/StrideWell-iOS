//
//  PlanAPI.swift
//  Stridewell
//

import Foundation

extension APIClient {

    /// Fetch a specific plan version by ID. Safe to call pre-confirmation
    /// (queries plan_versions directly, no current_plans dependency).
    /// - Parameter weeks: Limit to N weeks. Omit to return all weeks.
    func planVersion(id: String, weeks: Int? = nil) async -> ApiResult<PlanVersionResponse> {
        var path = "\(APIEndpoints.planVersion)/\(id)"
        if let w = weeks { path += "?weeks=\(w)" }
        return await get(path: path)
    }

    /// Fetch today's planned workout. 404 if no current plan exists.
    func planToday() async -> ApiResult<PlanDay> {
        await get(path: APIEndpoints.planToday)
    }

    /// Fetch the current active plan for a date window.
    /// Used by HomeScreen (M7) and PlanScreen (M8).
    func planWeek(start: String) async -> ApiResult<PlanWeekResponse> {
        await get(path: "\(APIEndpoints.planWeek)?start=\(start)")
    }
}
