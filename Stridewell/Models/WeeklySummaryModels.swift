//
//  WeeklySummaryModels.swift
//  Stridewell
//
//  V2 Phase 2 — mirrors GET /analysis/weekly response (spec §7.3).
//

import Foundation

struct WeeklyLongRun: Codable {
    let date: String
    let distance_m: Double
    let pace_s_per_km: Double
}

struct WeeklyQualitySession: Codable, Identifiable {
    let date: String
    let type: String
    let execution_quality: String

    var id: String { date + type }
}

struct WeeklySummary: Codable {
    let week_start: String
    let total_distance_m: Double
    let total_duration_s: Int
    let run_count: Int
    let planned_run_count: Int
    let compliance_rate: Double
    let avg_easy_pace_s_per_km: Double?
    let long_run: WeeklyLongRun?
    let quality_sessions: [WeeklyQualitySession]
    let fatigue_trend: String
    let volume_vs_previous_week_pct: Double?
}
