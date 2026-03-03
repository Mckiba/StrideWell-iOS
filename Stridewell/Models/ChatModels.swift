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
