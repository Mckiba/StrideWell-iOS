//
//  RunModels.swift
//  Stridewell
//
//  Activity (run) models from GET /runs/recent.
//

import Foundation

struct Run: Codable, Identifiable {
    let id: String
    let provider: String
    let sport_type: String
    let start_time: String       // ISO 8601
    let distance_m: Double
    let duration_s: Int
    let avg_pace_s_per_km: Double?
    let elevation_gain_m: Double
}

struct RecentRunsResponse: Codable {
    let runs: [Run]
}
