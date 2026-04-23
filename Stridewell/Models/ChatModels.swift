//
//  ChatModels.swift
//  Stridewell
//

import Foundation

enum MessageRole: String, Codable {
    case user
    case assistant
}

enum AgentUsed: String, Codable {
    case coach
    case explainer
    case adjuster
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
