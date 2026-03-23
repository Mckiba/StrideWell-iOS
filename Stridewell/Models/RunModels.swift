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
}

struct RecentRunsResponse: Codable {
    let runs: [Run]
    let hasMore: Bool?  // nil when fetched via the HomeScreen 3-item call on older server
}
