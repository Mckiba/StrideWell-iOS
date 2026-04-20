//
//  WorkoutModels.swift
//  Stridewell
//

import Foundation

enum WorkoutType: String, Codable {
    case easy
    case long_run
    case tempo
    case intervals
    case hills
    case recovery
    case rest
    case cross_train
    case race
}

enum WorkoutIntensity: String, Codable {
    case very_easy
    case easy
    case moderate
    case hard
    case very_hard
}

/// Target pace range (seconds per km).
/// `min_s_per_km` is the faster end (lower number), `max_s_per_km` the slower end.
struct PaceRange: Codable {
    let min_s_per_km: Double
    let max_s_per_km: Double
}

struct Workout: Codable {
    let type: WorkoutType
    let label: String
    let description: String?
    let target_distance_m: Double?
    let target_duration_s: Int?
    let target_pace_s_per_km: Double?
    let intensity: WorkoutIntensity?
    let notes: String?
    // V2 Phase 2 (M2.6): optional range + effort descriptor.
    // Backward compatible — older plan versions omit these, UI falls back to `target_pace_s_per_km`.
    // Declared with defaults so existing call sites/previews keep working without the new args.
    let target_pace_range: PaceRange?
    let effort_level: String?

    init(
        type: WorkoutType,
        label: String,
        description: String? = nil,
        target_distance_m: Double? = nil,
        target_duration_s: Int? = nil,
        target_pace_s_per_km: Double? = nil,
        intensity: WorkoutIntensity? = nil,
        notes: String? = nil,
        target_pace_range: PaceRange? = nil,
        effort_level: String? = nil
    ) {
        self.type = type
        self.label = label
        self.description = description
        self.target_distance_m = target_distance_m
        self.target_duration_s = target_duration_s
        self.target_pace_s_per_km = target_pace_s_per_km
        self.intensity = intensity
        self.notes = notes
        self.target_pace_range = target_pace_range
        self.effort_level = effort_level
    }
}
