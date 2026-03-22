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

struct ChatMessage: Codable, Identifiable {
    let id: String
    let role: MessageRole
    let content: String
    let agent_used: AgentUsed?
    let created_at: String
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
