//
//  ChatStore.swift
//  Stridewell
//
//  M10: Manages chat conversation state.
//  Persists conversation_id to UserDefaults so the same thread
//  resumes across app launches. Messages are in-memory only
//  (no history-fetch endpoint exists yet).
//

import Foundation

@Observable
final class ChatStore {

    // MARK: - Published State

    private(set) var conversationId: String?
    private(set) var messages: [ChatMessage] = []

    // MARK: - Init

    init() {
        conversationId = UserDefaults.standard.string(forKey: Self.conversationIdKey)
    }

    // MARK: - Mutators

    func setConversationId(_ id: String) {
        conversationId = id
        UserDefaults.standard.set(id, forKey: Self.conversationIdKey)
    }

    func addMessage(_ message: ChatMessage) {
        messages.append(message)
    }

    func reset() {
        conversationId = nil
        messages = []
        UserDefaults.standard.removeObject(forKey: Self.conversationIdKey)
    }

    // MARK: - Private

    private static let conversationIdKey = "ChatStore.conversationId"
}
