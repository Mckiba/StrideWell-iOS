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

    @State private var inputText = ""
    @State private var screenState: ScreenState = .empty
    @State private var pendingMessage: String? = nil

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
        VStack(spacing: 0) {
            if screenState == .empty {
                emptyState
            } else {
                messageThread
            }

            Divider()
            inputBar
        }
        .navigationTitle("Chat")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Empty State (Suggested Prompts)

    private var emptyState: some View {
        ScrollView {
            VStack(spacing: Spacing.lg) {
                Spacer().frame(height: Spacing.xxl)

                Image(systemName: "bubble.left.and.bubble.right")
                    .font(.system(size: 40))
                    .foregroundStyle(.tertiary)

                Text("Ask your coach anything")
                    .font(.sectionTitle)
                    .foregroundStyle(.secondary)

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
                                .background(Color(.secondarySystemBackground))
                                .clipShape(RoundedRectangle(cornerRadius: CornerRadius.md))
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, Spacing.lg)
            }
            .frame(maxWidth: .infinity)
        }
    }

    private var suggestedPrompts: [String] {
        [
            "Why did my plan change?",
            "I missed today's run",
            "How am I progressing?"
        ]
    }

    // MARK: - Message Thread

    private var messageThread: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 12) {
                    ForEach(chatStore.messages) { msg in
                        ChatBubble(message: msg)
                    }

                    if screenState == .waiting {
                        HStack {
                            ChatTypingIndicator()
                                .padding(.leading, 16)
                            Spacer()
                        }
                        .id("typing")
                    }

                    if case .error(let errorMsg) = screenState {
                        ChatInlineError(message: errorMsg) {
                            Task { await retry() }
                        }
                        .padding(.horizontal, 16)
                        .id("error")
                    }

                    Color.clear.frame(height: 8).id("bottom")
                }
                .padding(.vertical, 16)
            }
            .onChange(of: chatStore.messages.count) {
                withAnimation(.easeOut(duration: 0.2)) { proxy.scrollTo("bottom") }
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
        HStack(alignment: .bottom, spacing: 8) {
            TextField("Message…", text: $inputText, axis: .vertical)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 20))
                .lineLimit(1...5)

            Button {
                Task { await sendMessage(content: inputText) }
            } label: {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.system(size: 32))
                    .foregroundStyle(canSend ? Color.accentColor : Color(.tertiaryLabel))
            }
            .disabled(!canSend)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(Color(.systemBackground))
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
            created_at: Self.isoFormatter.string(from: Date())
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
                    try? await Task.sleep(nanoseconds: 5_000_000_000)
                    if case .success(let day) = await apiClient.planToday() {
                        planStore.setTodayPlanDay(day)
                    }
                }
            }

        case .failure(_, let errorMessage):
            screenState = .error(errorMessage)
        }
    }

    // MARK: - Helpers

    private static let isoFormatter: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime]
        return f
    }()
}

// MARK: - Chat Bubble

private struct ChatBubble: View {
    let message: ChatMessage

    private var isUser: Bool { message.role == .user }

    var body: some View {
        VStack(alignment: isUser ? .trailing : .leading, spacing: 2) {
            HStack(alignment: .bottom, spacing: 0) {
                if isUser { Spacer(minLength: 56) }

                Text(message.content)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(isUser ? Color.accentColor : Color(.secondarySystemBackground))
                    .foregroundStyle(isUser ? Color.white : Color.primary)
                    .clipShape(RoundedRectangle(cornerRadius: 18))
                    .textSelection(.enabled)

                if !isUser { Spacer(minLength: 56) }
            }

            // Agent label for assistant messages
            if !isUser, let agent = message.agent_used {
                Text(agent.rawValue)
                    .font(.cardCaption)
                    .foregroundStyle(.tertiary)
                    .padding(.leading, 4)
            }
        }
        .padding(.horizontal, 16)
        .frame(maxWidth: .infinity, alignment: isUser ? .trailing : .leading)
    }
}

// MARK: - Typing Indicator

private struct ChatTypingIndicator: View {
    @State private var phase = 0

    var body: some View {
        HStack(spacing: 5) {
            ForEach(0..<3, id: \.self) { index in
                Circle()
                    .frame(width: 8, height: 8)
                    .foregroundStyle(Color(.tertiaryLabel))
                    .scaleEffect(phase == index ? 1.4 : 1.0)
                    .animation(.spring(duration: 0.3), value: phase)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .task {
            while !Task.isCancelled {
                phase = (phase + 1) % 3
                try? await Task.sleep(nanoseconds: 400_000_000)
            }
        }
    }
}

// MARK: - Inline Error

private struct ChatInlineError: View {
    let message: String
    let onRetry: () -> Void

    var body: some View {
        VStack(spacing: 6) {
            Text(message)
                .font(.subheadline)
                .foregroundStyle(.red)
                .multilineTextAlignment(.center)
            Button("Try again", action: onRetry)
                .font(.subheadline.weight(.medium))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
    }
}
