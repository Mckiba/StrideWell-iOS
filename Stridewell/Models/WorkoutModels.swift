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

struct Workout: Codable {
    let type: WorkoutType
    let label: String
    let description: String?
    let target_distance_m: Double?
    let target_duration_s: Int?
    let target_pace_s_per_km: Double?
    let intensity: WorkoutIntensity?
    let notes: String?
}
