//
//  ChatModels.swift
//  Stridewell
//

import Foundation

enum MessageRole: String, Codable {
    case user
    case assistant
}

/// Which backend agent produced an assistant message.
/// Decoding is lenient: any value the app does not recognise becomes `.unknown`
/// rather than failing the whole response. A single unknown value used to fail
/// the entire GET /chat/history decode and silently blank the thread.
enum AgentUsed: String, Codable {
    case coach
    case explainer
    case adjuster
    case architect
    case coachProactive = "coach_proactive"
    case unknown

    init(from decoder: Decoder) throws {
        let raw = try decoder.singleValueContainer().decode(String.self)
        self = AgentUsed(rawValue: raw) ?? .unknown
    }

    /// Subtitle shown under an assistant bubble. nil hides the label.
    var displayName: String? {
        switch self {
        case .coach, .coachProactive: return "coach"
        case .explainer:              return "explainer"
        case .adjuster:               return "adjuster"
        case .architect:              return "plan builder"
        case .unknown:                return nil
        }
    }
}

enum FeedbackVote: String, Codable {
    case up
    case down
}

struct MessageFeedback: Codable, Equatable {
    var vote: FeedbackVote
    var comment: String?
}

struct ChatMessage: Codable, Identifiable {
    let id: String
    let role: MessageRole
    let content: String
    let agent_used: AgentUsed?
    let created_at: String
    // Mutable so ChatStore can apply optimistic updates and rollbacks.
    // Server hydrates this from message_feedback on GET /chat/history.
    var feedback: MessageFeedback?
}

// MARK: - Request / Response (M10)

struct ChatMessageRequest: Encodable {
    let message: String
    let conversation_id: String?
}

struct ChatMessageResponse: Decodable {
    let conversation_id: String
    let message: ChatMessage
}

// MARK: - History (M14)

struct ChatHistoryResponse: Decodable {
    let messages: [ChatMessage]
    let has_more: Bool
}
