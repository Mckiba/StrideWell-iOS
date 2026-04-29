//
//  RunDetailModels.swift
//  Stridewell
//
//  Response models for GET /runs/:runId.
//

import Foundation

struct RunDetail: Codable {
    let id: String
    let title: String?
    let description: String?
    let provider: String
    let sport_type: String
    let start_time: String
    let timezone: String
    let start_latlng: [Double]?
    let distance_m: Double
    let duration_s: Int
    let moving_time_s: Int?
    let elapsed_time_s: Int?
    let avg_pace_s_per_km: Double?
    let best_pace_s_per_km: Double?
    let avg_hr_bpm: Int?
    let max_hr_bpm: Int?
    let avg_cadence_spm: Int?
    let avg_power_w: Int?
    let calories_kcal: Int?
    let elevation_gain_m: Double?
    let elevation_loss_m: Double?
    let route: RunRoute?
}

struct RunSplit: Codable, Identifiable {
    var id: Int { index }
    let index: Int
    let distance_m: Double
    let duration_s: Int
    let avg_pace_s_per_km: Double
    let avg_hr_bpm: Int?
    let avg_cadence_spm: Int?
    let elevation_gain_m: Double?
    let source: String
}

struct RunStreams: Codable {
    let distance_m: [Double]
    let altitude_m: [Double]?
    let heartrate: [Double]?
    let cadence: [Double]?
}

struct RunDetailResponse: Codable {
    let run: RunDetail
    let splits: [RunSplit]
    let streams: RunStreams?
}
