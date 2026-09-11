//
//  ChatStore.swift
//  Stridewell
//
//

import Foundation

@Observable
final class ChatStore {

    // MARK: - Screen State
    //
    // Owned by the store rather than ChatScreen so a tab teardown cannot lose
    // the waiting/error state or strand a retry.

    enum ScreenState: Equatable {
        case empty          // no messages — show suggested prompts
        case active         // conversation in progress
        case waiting        // message sent, awaiting reply
        case error(String)  // inline error with retry, thread preserved
    }

    private(set) var screenState: ScreenState = .empty

    /// Last message the user tried to send, retained so retry works after the
    /// screen is rebuilt. Cleared once the send succeeds.
    private(set) var pendingMessage: String? = nil

    // MARK: - State

    private(set) var conversationId: String?
    private(set) var messages: [ChatMessage] = []

    // MARK: - Banner Auto-Send
    /// Set before switching to the Chat tab to trigger an automatic first message.
    /// ChatScreen consumes and clears this on appear / onChange.
    var pendingInitialMessage: String? = nil

    // MARK: - History State (M14)

    /// True when there are older messages on the server not yet loaded.
    private(set) var hasMoreHistory: Bool = false

    /// True while a history fetch is in flight — prevents concurrent loads.
    private(set) var isLoadingHistory: Bool = false

    /// True while a message send is in flight. Blocks history refreshes so a
    /// response cannot land on top of an optimistic message.
    private(set) var isSending: Bool = false

    /// True once history has loaded successfully at least once this launch.
    private(set) var hasLoadedHistory: Bool = false

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
        screenState = messages.isEmpty ? .empty : .active
    }

    // MARK: - History Loading (M14)

    /// Fetches the latest 50 messages and merges them into the thread.
    /// Safe to call repeatedly — guarded by isLoadingHistory and skipped while
    /// a send is in flight. On network failure the local cache is kept.
    func loadInitialHistory(api: APIClient) async {
        guard !isLoadingHistory, !isSending else { return }
        isLoadingHistory = true
        defer { isLoadingHistory = false }

        guard case .success(let response) = await api.chatHistory(before: nil, limit: 50) else {
            // On fetch failure: silently keep the UserDefaults seed.
            // Connectivity state is owned by ConnectivityStore — screens read from there.
            return
        }

        merge(serverPage: response.messages)
        hasMoreHistory = response.has_more
        hasLoadedHistory = true
        oldestCursor = messages.first?.created_at
        if screenState == .empty && !messages.isEmpty { screenState = .active }

        persistCache()
    }

    /// Fetches the next older page and PREPENDS to messages.
    /// Called by ChatScreen's scroll-to-top sentinel.
    func loadMoreHistory(api: APIClient) async {
        guard hasMoreHistory, !isLoadingHistory, let cursor = oldestCursor else { return }
        isLoadingHistory = true
        defer { isLoadingHistory = false }

        guard case .success(let response) = await api.chatHistory(before: cursor, limit: 50) else {
            return
        }

        let knownIds = Set(messages.map(\.id))
        let olderPage = response.messages.filter { !knownIds.contains($0.id) }
        messages = olderPage + messages            // prepend older messages
        hasMoreHistory = response.has_more
        oldestCursor = messages.first?.created_at

        persistCache()
    }

    /// Splices the newest server page into the thread instead of replacing it.
    /// Messages older than the page (pulled in by loadMoreHistory) are kept, and
    /// so is anything newer than the page — an optimistic send still in flight.
    /// An empty page is ignored so a blank response can never wipe the cache.
    private func merge(serverPage: [ChatMessage]) {
        guard !serverPage.isEmpty else { return }

        let serverIds = Set(serverPage.map(\.id))
        let serverDates = serverPage.compactMap { DateUtils.parseISO8601($0.created_at) }
        guard let oldestServer = serverDates.min(),
              let newestServer = serverDates.max() else { return }

        // Timestamps are compared as Dates, not strings: optimistic messages are
        // stamped without fractional seconds while the backend writes them with.
        var older: [ChatMessage] = []
        var newer: [ChatMessage] = []
        for msg in messages where !serverIds.contains(msg.id) {
            guard let sent = DateUtils.parseISO8601(msg.created_at) else { continue }
            if sent < oldestServer {
                older.append(msg)
            } else if sent > newestServer {
                // Only an unconfirmed local send can be newer than the whole page.
                newer.append(msg)
            }
        }

        messages = older + serverPage + newer
    }

    // MARK: - Mutators

    func setConversationId(_ id: String) {
        conversationId = id
        UserDefaults.standard.set(id, forKey: Self.conversationIdKey)
    }

    /// Drops a conversation the backend rejected (404 missing / 403 foreign) so
    /// the next send starts a fresh thread instead of failing forever.
    func clearConversationId() {
        conversationId = nil
        UserDefaults.standard.removeObject(forKey: Self.conversationIdKey)
    }

    func addMessage(_ message: ChatMessage) {
        messages.append(message)
        if oldestCursor == nil {
            oldestCursor = message.created_at
        }
        persistCache()
    }

    // MARK: - Send State

    func beginSending(_ content: String) {
        pendingMessage = content
        isSending = true
        screenState = .waiting
    }

    func finishSending(success: Bool, errorMessage: String? = nil) {
        isSending = false
        if success {
            pendingMessage = nil
            screenState = .active
        } else {
            screenState = .error(errorMessage ?? "Something went wrong.")
        }
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
        hasMoreHistory = false
        isLoadingHistory = false
        isSending = false
        hasLoadedHistory = false
        pendingMessage = nil
        pendingInitialMessage = nil
        screenState = .empty
        oldestCursor = nil
        UserDefaults.standard.removeObject(forKey: Self.conversationIdKey)
        UserDefaults.standard.removeObject(forKey: Self.messagesKey)
    }

    // MARK: - Private

    private static let conversationIdKey = "ChatStore.conversationId"
    private static let messagesKey       = "ChatStore.messages"

    /// Number of most-recent messages kept on disk. Covers the pages a user is
    /// likely to scroll back through without unbounded UserDefaults growth.
    private static let cacheLimit = 200

    private func persistCache() {
        let toCache = Array(messages.suffix(Self.cacheLimit))
        if let data = try? JSONEncoder().encode(toCache) {
            UserDefaults.standard.set(data, forKey: Self.messagesKey)
        }
    }
}
