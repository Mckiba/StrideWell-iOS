//
//  FitnessProfileModels.swift
//  Stridewell
//
//  V2 Phase 2 — mirrors the backend `FitnessProfile` shape.
//  Reuses `PaceRange` from WorkoutModels.swift.
//

import Foundation

struct HRRange: Codable {
    let min_bpm: Int
    let max_bpm: Int
}

struct PaceZones: Codable {
    let recovery: PaceRange
    let easy: PaceRange
    let moderate: PaceRange
    let tempo: PaceRange
    let threshold: PaceRange
    let interval: PaceRange
    let repetition: PaceRange
}

struct HRZones: Codable {
    let max_hr_bpm: Int
    let max_hr_source: String  // observed | athlete_reported | age_estimated
    let zone_1: HRRange
    let zone_2: HRRange
    let zone_3: HRRange
    let zone_4: HRRange
    let zone_5: HRRange
}

struct FitnessProfileHistoryEntry: Codable, Identifiable {
    let threshold_pace_s_per_km: Double
    let date: String
    let method: String

    var id: String { date + method }
}

struct FitnessProfile: Codable {
    let estimated_threshold_pace_s_per_km: Double?
    let estimation_method: String?        // race_result | time_trial | training_data_inference | athlete_reported
    let estimation_date: String?
    let estimation_source: String?
    let confidence: String?               // high | medium | low
    let pace_zones: PaceZones?
    let hr_zones: HRZones?
    let history: [FitnessProfileHistoryEntry]
}
