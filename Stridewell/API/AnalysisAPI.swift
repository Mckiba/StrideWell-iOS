//
//  AnalysisAPI.swift
//  Stridewell
//
//  V2 Phase 2 endpoints: stored per-run analysis and the user's fitness profile
//  (threshold pace, pace zones, HR zones). All reads; analysis computation is
//  driven by the backend's COMPUTE_RUN_ANALYSIS worker.
//

import Foundation

extension APIClient {

    /// GET /runs/:runId/analysis — returns flattened stored run analysis
    /// (execution, HR, trends, planned-vs-actual).
    /// 404 may mean analysis not ready or run not found; caller decides UX.
    func runAnalysis(runId: String) async -> ApiResult<RunAnalysisResponse> {
        await get(path: "\(APIEndpoints.runAnalysis)/\(runId)/analysis")
    }

    /// GET /profile/fitness — returns flattened fitness profile fields
    /// (threshold estimate, pace zones, HR zones). 404 before profile exists.
    func fitnessProfile() async -> ApiResult<FitnessProfile> {
        await get(path: APIEndpoints.profileFitness)
    }

    /// GET /analysis/weekly?start=YYYY-MM-DD — week summary (distance, compliance,
    /// long run, quality sessions). Computed on demand by the backend.
    func weeklySummary(weekStart: String) async -> ApiResult<WeeklySummary> {
        await get(path: "\(APIEndpoints.analysisWeekly)?start=\(weekStart)")
    }
}
