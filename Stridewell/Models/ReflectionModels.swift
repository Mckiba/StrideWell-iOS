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

// MARK: - Submission types (M9)

/// POST body for /reflection — only client-side fields.
/// Backend injects user_id and submitted_at; constraints derived by Interpreter Agent.
struct ReflectionSubmission: Encodable {
    let fatigue: Int            // 1–10
    let sleep_quality: Int      // 1–10
    let mood: Int               // 3, 5, or 8
    let soreness: [SorenessEntry]?
    let free_text: String?
    let related_run_id: String?
}

/// Response from POST /reflection.
struct ReflectionResponse: Decodable {
    let stored: Bool
    let reflection_id: String
}

/// Mutable form model for the soreness list in ReflectionScreen.
/// Slider requires Double; converts to Int on submission.
struct SorenessFormEntry: Identifiable {
    let id = UUID()
    var location: String = ""
    var score: Double = 5

    /// Convert to API-ready entry. Returns nil if location is blank.
    func toSubmission() -> SorenessEntry? {
        let trimmed = location.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        return SorenessEntry(location: trimmed, score: Int(score))
    }
}
