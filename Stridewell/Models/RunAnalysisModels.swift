//
//  RunAnalysisModels.swift
//  Stridewell
//
//  V2 Phase 2 — mirrors the backend shapes from `analysis.types.ts`.
//  All nested data blocks are independently optional: the analyzer may
//  populate some steps while leaving others null ("partial" status).
//

import Foundation

// MARK: - Execution Analysis

struct ExecutionAnalysis: Codable {
    let pace_consistency: PaceConsistency
    let segments: [ExecutionSegment]
    let execution_quality: ExecutionQuality?
    let stopped_time_s: Int?
    let stop_ratio: Double?
}

struct PaceConsistency: Codable {
    let coefficient_of_variation: Double
    let classification: String  // very_even | even | moderate_variation | high_variation
    let split_profile: String   // negative | even | positive | erratic
    let first_half_avg_pace_s_per_km: Double
    let second_half_avg_pace_s_per_km: Double
    let pace_delta_s: Double
}

struct ExecutionSegment: Codable, Identifiable {
    let segment_index: Int
    let distance_m: Double
    let pace_s_per_km: Double
    let hr_bpm: Int?
    let elevation_delta_m: Double?

    var id: Int { segment_index }
}

struct ExecutionQuality: Codable {
    let score: String  // excellent | good | fair | poor
    let factors: [String]
}

// MARK: - HR Analysis

struct HRAnalysis: Codable {
    let avg_hr_bpm: Int
    let max_hr_bpm: Int?
    let cardiac_drift: CardiacDrift?
    let efficiency: HREfficiency?
    let zone_distribution: HRZoneDistribution?
}

struct CardiacDrift: Codable {
    let first_half_avg_hr: Int
    let second_half_avg_hr: Int
    let drift_bpm: Int
    let drift_pct: Double
    let significant: Bool
    let interpretation: String
}

struct HREfficiency: Codable {
    let pace_per_hr_beat: Double
    let vs_recent_avg: Double?
    let trend: String  // improving | stable | declining | insufficient_data
}

struct HRZoneDistribution: Codable {
    let zone_1_pct: Double
    let zone_2_pct: Double
    let zone_3_pct: Double
    let zone_4_pct: Double
    let zone_5_pct: Double
    let primary_zone: Int
    let appropriate_for_workout: Bool?
    let zone_note: String?
}

// MARK: - Trend Context

struct TrendContext: Codable {
    let weekly_volume: WeeklyVolume
    let pace_trend: PaceTrend
    let long_run_progression: LongRunProgression?
    let runs_this_week: Int
    let runs_last_week: Int
    let streak_days: Int
    let compliance_last_14_days: Compliance
}

struct WeeklyVolume: Codable {
    let current_week_km: Double
    let previous_week_km: Double
    let four_week_avg_km: Double
    let trend: String  // increasing | stable | decreasing | insufficient_data
}

struct PaceTrend: Codable {
    let workout_type: String
    let last_6_runs: [PaceTrendSample]
    let trend: String  // improving | stable | declining | insufficient_data
    let trend_rate_s_per_km_per_week: Double?
    let note: String?
}

struct PaceTrendSample: Codable, Identifiable {
    let date: String
    let avg_pace_s_per_km: Double
    let distance_m: Double

    var id: String { date }
}

struct LongRunProgression: Codable {
    let last_4_long_runs: [LongRunSample]
    let distance_trend: String
    let longest_recent_m: Double
}

struct LongRunSample: Codable, Identifiable {
    let date: String
    let distance_m: Double
    let avg_pace_s_per_km: Double

    var id: String { date }
}

struct Compliance: Codable {
    let planned: Int
    let completed: Int
    let rate: Double
}

// MARK: - Planned vs Actual

struct PlannedVsActual: Codable {
    let distance_delta_m: Double?
    let pace_delta_s_per_km: Double?
    let duration_delta_s: Double?
    let completed_as_planned: Bool
    let notes: String
}

// MARK: - Stored Run Analysis (response from GET /runs/:id/analysis)

struct RunAnalysisData: Codable {
    let execution_analysis: ExecutionAnalysis?
    let hr_analysis: HRAnalysis?
    let trend_context: TrendContext?
    let planned_vs_actual: PlannedVsActual?
}

struct RunAnalysisResponse: Codable {
    let run_id: String
    let status: String?  // "complete" | "partial" (optional for spec compatibility)
    let computed_at: String
    let execution_analysis: ExecutionAnalysis?
    let hr_analysis: HRAnalysis?
    let trend_context: TrendContext?
    let planned_vs_actual: PlannedVsActual?

    var analysisData: RunAnalysisData {
        RunAnalysisData(
            execution_analysis: execution_analysis,
            hr_analysis: hr_analysis,
            trend_context: trend_context,
            planned_vs_actual: planned_vs_actual
        )
    }
}
