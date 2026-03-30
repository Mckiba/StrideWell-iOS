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

    @State private var inputText = ""
    @State private var screenState: ScreenState = .empty
    @State private var pendingMessage: String? = nil
    @State private var initialLoadDone = false

    enum ScreenState: Equatable {
        case empty          // no messages — show suggested prompts
        case active         // conversation in progress
        case waiting        // message sent, awaiting reply
        case error(String)  // inline error with retry, thread preserved

        static func == (lhs: ScreenState, rhs: ScreenState) -> Bool {
            switch (lhs, rhs) {
            case (.empty, .empty), (.active, .active), (.waiting, .waiting): return true
            case (.error(let a), .error(let b)): return a == b
            default: return false
            }
        }
    }

    var body: some View {
        ZStack {
            HeatmapBackgroundView(userId: authStore.userId ?? "")

            VStack(spacing: 0) {
                conversationView

                Divider()
                inputBar
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            if !chatStore.messages.isEmpty { screenState = .active }
            guard !initialLoadDone else {
                // Screen already loaded — consume any pending message set while it was visible
                if let msg = chatStore.pendingInitialMessage {
                    chatStore.pendingInitialMessage = nil
                    Task { await sendMessage(content: msg) }
                }
                return
            }
            initialLoadDone = true
            Task {
                await chatStore.loadInitialHistory(api: apiClient)
                // Auto-send initial message from banner tap, guarded by consumption
                if let msg = chatStore.pendingInitialMessage {
                    chatStore.pendingInitialMessage = nil
                    await sendMessage(content: msg)
                }
            }
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
                                Task { await chatStore.loadMoreHistory(api: apiClient) }
                            }
                    }

                    if chatStore.messages.isEmpty && !chatStore.isLoadingHistory {
                        emptyHeader
                    }

                    ForEach(chatStore.messages) { msg in
                        ChatBubbleView(
                            content: msg.content,
                            isUser: msg.role == .user,
                            subtitle: msg.role == .user ? nil : msg.agent_used?.rawValue
                        )
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

                    suggestedPromptsSection

                    Color.clear.frame(height: Spacing.sm).id("bottom")
                }
                .padding(.vertical, Spacing.md)
            }
            // Auto-scroll to bottom only when a new message is appended (last ID changed),
            // not when older history is prepended — this preserves scroll position.
            .onChange(of: chatStore.messages.last?.id) { _, _ in
                if !chatStore.isLoadingHistory {
                    withAnimation(.easeOut(duration: 0.2)) { proxy.scrollTo("bottom") }
                }
            }
            // Jump to bottom (no animation) after the initial history load completes.
            .onChange(of: initialLoadDone) { _, done in
                if done { proxy.scrollTo("bottom", anchor: .bottom) }
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
        !inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    // MARK: - Send Message

    private func sendMessage(content: String) async {
        let trimmed = content.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        inputText = ""
        pendingMessage = trimmed

        // Create an optimistic local user message for the thread
        let userMessage = ChatMessage(
            id: UUID().uuidString,
            role: .user,
            content: trimmed,
            agent_used: nil,
            created_at: DateUtils.isoDateTimeFormatter.string(from: Date())
        )
        chatStore.addMessage(userMessage)
        screenState = .waiting

        let result = await apiClient.sendChatMessage(
            conversationId: chatStore.conversationId,
            message: trimmed
        )
        handleResult(result)
    }

    // MARK: - Retry

    private func retry() async {
        guard let message = pendingMessage else { return }
        screenState = .waiting

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
            pendingMessage = nil

            // Persist conversation_id for future messages / app relaunches
            chatStore.setConversationId(response.conversation_id)

            // Append assistant reply
            chatStore.addMessage(response.message)
            screenState = .active

            // If the Adjuster agent responded, poll for the updated plan
            if response.message.agent_used == .adjuster {
                Task {
                    try? await Task.sleep(for: .seconds(5))
                    if case .success(let day) = await apiClient.planToday() {
                        planStore.setTodayPlanDay(day)
                    }
                }
            }

        case .failure(_, let errorMessage):
            screenState = .error(errorMessage)
        }
    }

}

