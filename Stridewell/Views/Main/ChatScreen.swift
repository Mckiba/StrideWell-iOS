//
//  ChatScreen.swift
//  Stridewell
//
//  M10: Post-onboarding conversational chat with AI coach.
//  Supports agent labelling, adjuster plan-polling, and
//  suggested prompts on empty state.
//

import SwiftUI

struct ChatScreen: View {

    @Environment(\.apiClient) private var apiClient
    @Environment(\.chatStore) private var chatStore
    @Environment(\.planStore) private var planStore
    @Environment(\.authStore) private var authStore
    @Environment(\.connectivityStore) private var connectivityStore

    @Environment(\.scenePhase) private var scenePhase

    @State private var inputText = ""
    /// Set once the user actually drags the thread. Gates the history sentinel so
    /// it cannot page in the whole conversation on its own during layout.
    @State private var userHasScrolled = false
    @FocusState private var isInputFocused: Bool

    /// Send/waiting/error state lives in ChatStore so it survives a tab teardown.
    private var screenState: ChatStore.ScreenState { chatStore.screenState }

    var body: some View {
        ZStack {
            HeatmapBackgroundView(userId: authStore.userId ?? "")

            VStack(spacing: 0) {
                conversationView

                if connectivityStore.isOffline {
                    OfflineBannerView(lastFetchDate: nil)
                        .padding(.horizontal, Spacing.md)
                }
                Divider()
                inputBar
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await chatStore.loadInitialHistory(api: apiClient)
            // Auto-send initial message from banner tap, guarded by consumption
            if let msg = chatStore.pendingInitialMessage {
                chatStore.pendingInitialMessage = nil
                await sendMessage(content: msg)
            }
        }
        // Pick up proactive coach messages sent while the app was backgrounded.
        .onChange(of: scenePhase) { _, phase in
            guard phase == .active else { return }
            Task { await chatStore.loadInitialHistory(api: apiClient) }
        }
        // Handles messages set while the screen is already visible and onAppear won't re-fire
        .onChange(of: chatStore.pendingInitialMessage) { _, msg in
            guard let msg else { return }
            chatStore.pendingInitialMessage = nil
            Task { await sendMessage(content: msg) }
        }
    }

    private var suggestedPrompts: [String] {
        [
            "Why did my plan change?",
            "I missed today's run",
            "How am I progressing?"
        ]
    }

    // MARK: - Empty Header

    private var emptyHeader: some View {
        VStack(spacing: Spacing.lg) {
            Spacer().frame(height: Spacing.xxl)

            Image(systemName: "bubble.left.and.bubble.right")
                .font(.system(size: 40))
                .foregroundStyle(.tertiary)

            Text("Ask your coach anything")
                .font(.sectionTitle)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.bottom, Spacing.md)
    }

    // MARK: - Suggested Prompts

    private var suggestedPromptsSection: some View {
        VStack(spacing: Spacing.sm) {
            ForEach(suggestedPrompts, id: \.self) { prompt in
                Button {
                    Task { await sendMessage(content: prompt) }
                } label: {
                    Text(prompt)
                        .font(.cardBody)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, Spacing.md)
                        .padding(.vertical, Spacing.sm)
                        .background(AppColor.surfaceElevated)
                        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.md))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, Spacing.lg)
        .padding(.top, chatStore.messages.isEmpty ? 0 : Spacing.lg)
    }

    // MARK: - Conversation View

    private var conversationView: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: Spacing.sm) {

                    // Scroll-to-top sentinel — appears when there are older pages.
                    // onAppear fires when the user scrolls up far enough to reveal it.
                    if chatStore.hasMoreHistory {
                        HStack { Spacer(); ProgressView(); Spacer() }
                            .id("history-sentinel")
                            .onAppear {
                                guard userHasScrolled, chatStore.hasLoadedHistory else { return }
                                Task { await chatStore.loadMoreHistory(api: apiClient) }
                            }
                    }

                    if chatStore.messages.isEmpty && !chatStore.isLoadingHistory {
                        emptyHeader
                    }

                    ForEach(chatStore.messages) { msg in
                        VStack(alignment: .leading, spacing: Spacing.xs) {
                            ChatBubbleView(
                                content: msg.content,
                                isUser: msg.role == .user,
                                subtitle: msg.role == .user ? nil : msg.agent_used?.displayName
                            )

                            if msg.role == .assistant {
                                MessageFeedbackView(
                                    feedback: msg.feedback,
                                    onVote: { vote in
                                        Task { await submitFeedback(messageId: msg.id, vote: vote, comment: nil) }
                                    },
                                    onCommentSubmit: { comment in
                                        Task { await submitFeedback(messageId: msg.id, vote: .down, comment: comment) }
                                    }
                                )
                            }
                        }
                        .id(msg.id)
                    }

                    if screenState == .waiting {
                        HStack {
                            TypingIndicatorView()
                                .padding(.leading, Spacing.md)
                            Spacer()
                        }
                        .id("typing")
                    }

                    if case .error(let errorMsg) = screenState {
                        InlineErrorView(message: errorMsg) {
                            Task { await retry() }
                        }
                        .padding(.horizontal, Spacing.md)
                        .id("error")
                    }

                    if chatStore.messages.isEmpty {
                        suggestedPromptsSection
                    }

                    Color.clear.frame(height: Spacing.sm).id("bottom")
                }
                .padding(.vertical, Spacing.md)
            }
            // Opens pinned to the newest message. This also keeps the
            // history sentinel off-screen so it only fires on a real scroll up.
            .defaultScrollAnchor(.bottom, for: .initialOffset)
            .scrollDismissesKeyboard(.interactively)
            .onScrollPhaseChange { _, phase in
                if phase == .interacting || phase == .tracking { userHasScrolled = true }
            }
            .simultaneousGesture(
                TapGesture().onEnded {
                    isInputFocused = false
                }
            )
            // Auto-scroll to bottom only when a new message is appended (last ID changed),
            // not when older history is prepended — this preserves scroll position.
            .onChange(of: chatStore.messages.last?.id) { _, _ in
                if !chatStore.isLoadingHistory {
                    withAnimation(.easeOut(duration: 0.2)) { proxy.scrollTo("bottom") }
                }
            }
            .onChange(of: screenState) {
                switch screenState {
                case .waiting:
                    withAnimation(.easeOut(duration: 0.2)) { proxy.scrollTo("typing") }
                case .error:
                    withAnimation(.easeOut(duration: 0.2)) { proxy.scrollTo("error") }
                default: break
                }
            }
        }
    }

    // MARK: - Input Bar

    private var inputBar: some View {
        HStack(alignment: .bottom, spacing: Spacing.sm) {
            TextField("Message…", text: $inputText, axis: .vertical)
                .padding(.horizontal, Spacing.sm)
                .padding(.vertical, Spacing.sm)
                .background(AppColor.surfaceElevated)
                .clipShape(RoundedRectangle(cornerRadius: CornerRadius.input))
                .lineLimit(1...5)
                .focused($isInputFocused)

            Button {
                Task { await sendMessage(content: inputText) }
            } label: {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.system(size: 32))
                    .foregroundStyle(canSend ? AppColor.accent : AppColor.textTertiary)
            }
            .disabled(!canSend)
        }
        .padding(.horizontal, Spacing.sm)
        .padding(.vertical, Spacing.sm)
        .background(AppColor.surface)
    }

    private var canSend: Bool {
        screenState != .waiting &&
        !connectivityStore.isOffline &&
        !inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    // MARK: - Send Message

    private func sendMessage(content: String) async {
        let trimmed = content.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        inputText = ""

        // Create an optimistic local user message for the thread
        let userMessage = ChatMessage(
            id: UUID().uuidString,
            role: .user,
            content: trimmed,
            agent_used: nil,
            created_at: DateUtils.isoDateTimeFormatter.string(from: Date())
        )
        chatStore.addMessage(userMessage)
        chatStore.beginSending(trimmed)

        let result = await apiClient.sendChatMessage(
            conversationId: chatStore.conversationId,
            message: trimmed
        )
        handleResult(result)
    }

    // MARK: - Retry

    private func retry() async {
        guard let message = chatStore.pendingMessage else { return }
        chatStore.beginSending(message)

        let result = await apiClient.sendChatMessage(
            conversationId: chatStore.conversationId,
            message: message
        )

        handleResult(result)
    }

    // MARK: - Handle Result

    private func handleResult(_ result: ApiResult<ChatMessageResponse>) {
        switch result {
        case .success(let response):
            // Persist conversation_id for future messages / app relaunches
            chatStore.setConversationId(response.conversation_id)

            // Append assistant reply
            chatStore.addMessage(response.message)
            chatStore.finishSending(success: true)

            // If the Adjuster agent responded, poll for the updated plan
            if response.message.agent_used == .adjuster {
                Task {
                    try? await Task.sleep(for: .seconds(5))
                    if case .success(let day) = await apiClient.planToday() {
                        planStore.setTodayPlanDay(day)
                    }
                }
            }

        case .failure(let status, let errorMessage):
            // The stored conversation is gone or belongs to another user —
            // drop it so the next send opens a fresh thread.
            if status == 404 || status == 403 {
                chatStore.clearConversationId()
            }
            chatStore.finishSending(success: false, errorMessage: errorMessage)
        }
    }

    // MARK: - Feedback

    /// Optimistically updates the message's feedback in the store, PUTs to the
    /// backend, then rolls back on network failure. Comment is nil for simple
    /// thumb taps; the thumbs-down comment field sends comment via the same path.
    private func submitFeedback(messageId: String, vote: FeedbackVote, comment: String?) async {
        let prior = chatStore.messages.first(where: { $0.id == messageId })?.feedback
        let optimistic = MessageFeedback(vote: vote, comment: comment)
        chatStore.setFeedback(messageId: messageId, feedback: optimistic)

        let result = await apiClient.sendMessageFeedback(
            messageId: messageId,
            vote: vote,
            comment: comment
        )

        if case .failure = result {
            chatStore.setFeedback(messageId: messageId, feedback: prior)
        }
    }

}
