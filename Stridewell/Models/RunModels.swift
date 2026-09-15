//
//  RunModels.swift
//  Stridewell
//
//  Activity (run) models from GET /runs/recent.
//

import Foundation

struct RunRoute: Codable {
    let summary_polyline: String?
}

struct Run: Codable, Identifiable {
    let id: String
    let provider: String
    let sport_type: String
    let title: String?
    let start_time: String       // ISO 8601
    let distance_m: Double
    let duration_s: Int
    let avg_pace_s_per_km: Double?
    let elevation_gain_m: Double
    let route: RunRoute?

    /// YYYY-MM-DD of the plan day this run fulfilled, or nil when the run is
    /// standalone (historical, cross-training, or outside the active plan).
    /// Populated by /runs/recent via LEFT JOIN plan_day_status.
    /// Drives the ActivityCard's bottom-stroke treatment — only linked runs
    /// get the accent stroke. Default nil so existing call-sites and cached
    /// payloads (pre-Phase-6-UI) continue to decode without changes.
    var plan_day_date: String? = nil
}

struct RecentRunsResponse: Codable {
    let runs: [Run]
    let hasMore: Bool?  // nil when fetched via the HomeScreen 3-item call on older server
    /// Completed/modified plan days linked to `runs`. Present only when
    /// requested with include_plan_day=true.
    var plan_days: [PlanDay]? = nil
}

// MARK: - Summary (GET /runs/summary)

struct RunSummaryResponse: Codable {
    let range: String          // week | month | year | all
    let start: String          // YYYY-MM-DD, inclusive
    let end: String            // YYYY-MM-DD, exclusive
    let totals: RunSummaryTotals
    let buckets: [RunSummaryBucket]
    let first_run_date: String?
}

struct RunSummaryTotals: Codable {
    let distance_m: Double
    let run_count: Int
    let duration_s: Int
    let avg_pace_s_per_km: Double?
}

struct RunSummaryBucket: Codable, Identifiable {
    let key: String            // YYYY-MM-DD, YYYY-MM, or YYYY
    let distance_m: Double
    let run_count: Int
    let run_id: String?        // set only when run_count == 1
    var id: String { key }
}
