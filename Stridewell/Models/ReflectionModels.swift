//
//  ReflectionModels.swift
//  Stridewell
//

import Foundation

struct SorenessEntry: Codable {
    let location: String
    let score: Int  // 1–10
}

struct Reflection: Codable {
    let user_id: String
    let submitted_at: String
    let fatigue: Int        // 1–10
    let sleep_quality: Int  // 1–10
    let mood: Int           // 1–10; UI maps 3-state selector → 3/5/8
    let soreness: [SorenessEntry]?
    let free_text: String?
    let related_run_id: String?
    let constraints: [String]?
}
