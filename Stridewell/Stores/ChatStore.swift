//
//  ChatStore.swift
//  Stridewell
//
//

import Foundation

@Observable
final class ChatStore {

    // MARK: - State

    private(set) var conversationId: String?
    private(set) var messages: [ChatMessage] = []

    // MARK: - Banner Auto-Send
    /// Set before switching to the Chat tab to trigger an automatic first message.
    /// ChatScreen consumes and clears this on appear / onChange.
    var pendingInitialMessage: String? = nil

    // MARK: - History State (M14)

    /// True when chat history is being served from the UserDefaults seed
    /// because the network is unavailable. Sending is blocked while offline.
    private(set) var isOffline: Bool = false

    /// True when there are older messages on the server not yet loaded.
    private(set) var hasMoreHistory: Bool = false

    /// True while a history fetch is in flight — prevents concurrent loads.
    private(set) var isLoadingHistory: Bool = false

    /// `created_at` of the oldest message in `messages`. Used as the `before`
    /// cursor when paginating backwards.
    private var oldestCursor: String? = nil

    // MARK: - Init

    init() {
        conversationId = UserDefaults.standard.string(forKey: Self.conversationIdKey)
        if let data = UserDefaults.standard.data(forKey: Self.messagesKey),
           let saved = try? JSONDecoder().decode([ChatMessage].self, from: data) {
            messages = saved
            oldestCursor = saved.first?.created_at   // first = oldest (ascending)
        }
    }

    // MARK: - History Loading (M14)

    /// Fetches the latest 50 messages from the backend and REPLACES the
    /// messages array. Safe to call multiple times — guarded by isLoadingHistory.
    /// On network failure: silently keeps the UserDefaults seed (offline resilience).
    func loadInitialHistory(api: APIClient) async {
        guard !isLoadingHistory else { return }
        isLoadingHistory = true
        defer { isLoadingHistory = false }

        guard case .success(let response) = await api.chatHistory(before: nil, limit: 50) else {
            // On network failure: serve the UserDefaults seed as offline cache
            if !messages.isEmpty {
                isOffline = true
            }
            return
        }

        isOffline = false
        messages = response.messages               // ascending: oldest → newest
        hasMoreHistory = response.has_more
        oldestCursor = response.messages.first?.created_at

        persistCache()
    }

    /// Fetches the next older page and PREPENDS to messages.
    /// Called by ChatScreen's scroll-to-top sentinel.
    /// Does NOT update the cache — older pages are ephemeral for this session.
    func loadMoreHistory(api: APIClient) async {
        guard hasMoreHistory, !isLoadingHistory, let cursor = oldestCursor else { return }
        isLoadingHistory = true
        defer { isLoadingHistory = false }

        guard case .success(let response) = await api.chatHistory(before: cursor, limit: 50) else {
            return
        }

        messages = response.messages + messages    // prepend older messages
        hasMoreHistory = response.has_more
        oldestCursor = response.messages.first?.created_at
    }

    // MARK: - Mutators

    func setConversationId(_ id: String) {
        conversationId = id
        UserDefaults.standard.set(id, forKey: Self.conversationIdKey)
    }

    func addMessage(_ message: ChatMessage) {
        messages.append(message)
        if oldestCursor == nil {
            oldestCursor = message.created_at
        }
        persistCache()
    }

    /// Replace the feedback on a stored message. Used for both optimistic
    /// updates (pre-network) and rollbacks (on network failure). No-op if the
    /// message id isn't in the list (e.g. already scrolled out of range).
    func setFeedback(messageId: String, feedback: MessageFeedback?) {
        guard let idx = messages.firstIndex(where: { $0.id == messageId }) else { return }
        messages[idx].feedback = feedback
        persistCache()
    }

    func reset() {
        conversationId = nil
        messages = []
        isOffline = false
        hasMoreHistory = false
        isLoadingHistory = false
        oldestCursor = nil
        UserDefaults.standard.removeObject(forKey: Self.conversationIdKey)
        UserDefaults.standard.removeObject(forKey: Self.messagesKey)
    }

    // MARK: - Private

    private static let conversationIdKey = "ChatStore.conversationId"
    private static let messagesKey       = "ChatStore.messages"

    /// Persists only the 50 most recent messages to UserDefaults.
    /// Older pages loaded via loadMoreHistory() are not persisted.
    private func persistCache() {
        let toCache = Array(messages.suffix(50))
        if let data = try? JSONEncoder().encode(toCache) {
            UserDefaults.standard.set(data, forKey: Self.messagesKey)
        }
    }
}
