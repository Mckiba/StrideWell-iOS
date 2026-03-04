//
//  IntakeInterviewScreen.swift
//  Stridewell
//

import SwiftUI

struct IntakeInterviewScreen: View {

    @Environment(\.onboardingStore) private var onboardingStore
    @Environment(\.apiClient) private var apiClient

    @State private var messages: [InterviewMessage] = []
    @State private var inputText = ""
    @State private var screenState: ScreenState = .loading
    @State private var navigateToPlanBuilding = false
    @State private var pendingMessage: InterviewMessage? = nil

    enum ScreenState: Equatable {
        case loading        // awaiting first coach message on screen open
        case active         // conversation live, input enabled
        case waiting        // message sent, awaiting reply
        case transitioning  // plan_building = true, navigating to PlanBuildingScreen
        case error(String)  // API failure — inline retry, thread preserved

        static func == (lhs: ScreenState, rhs: ScreenState) -> Bool {
            switch (lhs, rhs) {
            case (.loading, .loading), (.active, .active),
                 (.waiting, .waiting), (.transitioning, .transitioning): return true
            case (.error(let a), .error(let b)): return a == b
            default: return false
            }
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            messageThread

            if screenState != .transitioning {
                Divider()
                inputBar
            }
        }
        .navigationTitle("Intake Interview")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .navigationDestination(isPresented: $navigateToPlanBuilding) {
            PlanBuildingScreen()
        }
        .task { await triggerInitialMessage() }
    }

    // MARK: - Message Thread

    private var messageThread: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 12) {
                    ForEach(messages) { msg in
                        MessageBubble(message: msg)
                    }

                    if screenState == .waiting || screenState == .loading {
                        HStack {
                            TypingIndicator()
                                .padding(.leading, 16)
                            Spacer()
                        }
                        .id("typing")
                    }

                    if case .error(let errorMsg) = screenState {
                        InlineError(message: errorMsg) {
                            Task { await retry() }
                        }
                        .padding(.horizontal, 16)
                        .id("error")
                    }

                    Color.clear.frame(height: 8).id("bottom")
                }
                .padding(.vertical, 16)
            }
            .onChange(of: messages.count) {
                withAnimation(.easeOut(duration: 0.2)) { proxy.scrollTo("bottom") }
            }
            .onChange(of: screenState) {
                switch screenState {
                case .waiting, .loading:
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
                .disabled(screenState == .loading || screenState == .waiting)

            Button {
                Task { await sendMessage() }
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
        screenState == .active &&
        !inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    // MARK: - Initial Trigger

    /// Sends a silent "start" message to receive the first coach message.
    /// The trigger is not displayed in the UI — only the coach's reply is shown.
    /// Works for both fresh sessions and resumes (backend has full conversation history).
    private func triggerInitialMessage() async {
        guard let conversationId = onboardingStore.conversationId else {
            screenState = .error("No active conversation. Please go back and try again.")
            return
        }
        screenState = .loading
        let trigger = makeMessage(content: "start")
        pendingMessage = trigger

        let result: ApiResult<OnboardingMessageResponse> = await apiClient.sendOnboardingMessage(
            conversationId: conversationId,
            message: trigger
        )
        handleResult(result, isTrigger: true)
    }

    // MARK: - Send Message

    private func sendMessage() async {
        let content = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !content.isEmpty, let conversationId = onboardingStore.conversationId else { return }

        inputText = ""
        let userMsg = makeMessage(content: content)
        pendingMessage = userMsg
        messages.append(userMsg)
        screenState = .waiting

        let result: ApiResult<OnboardingMessageResponse> = await apiClient.sendOnboardingMessage(
            conversationId: conversationId,
            message: userMsg
        )
        handleResult(result, isTrigger: false)
    }

    // MARK: - Retry

    private func retry() async {
        if messages.isEmpty {
            // Initial trigger failed — try again with a fresh trigger
            await triggerInitialMessage()
        } else if let msg = pendingMessage, let conversationId = onboardingStore.conversationId {
            // User message failed — resend the same message
            screenState = .waiting
            let result: ApiResult<OnboardingMessageResponse> = await apiClient.sendOnboardingMessage(
                conversationId: conversationId,
                message: msg
            )
            handleResult(result, isTrigger: false)
        }
    }

    // MARK: - Handle Result

    private func handleResult(_ result: ApiResult<OnboardingMessageResponse>, isTrigger: Bool) {
        switch result {
        case .success(let response):
            pendingMessage = nil
            messages.append(response.reply)
            applyOnboardingState(response.onboarding_state)
            if screenState != .transitioning {
                screenState = .active
            }
        case .failure(_, let errorMessage):
            screenState = .error(errorMessage)
        }
    }

    private func applyOnboardingState(_ state: OnboardingMessageOnboardingState) {
        guard state.plan_building else { return }
        // Coach's final message is already appended — transition after a brief pause
        screenState = .transitioning
        Task {
            try? await Task.sleep(nanoseconds: 2_000_000_000)
            navigateToPlanBuilding = true
        }
    }

    // MARK: - Helpers

    private func makeMessage(content: String) -> InterviewMessage {
        InterviewMessage(
            id: UUID().uuidString,
            role: .user,
            content: content,
            agent_used: nil,
            created_at: Self.isoFormatter.string(from: Date())
        )
    }

    private static let isoFormatter: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime]
        return f
    }()
}

// MARK: - Message Bubble

private struct MessageBubble: View {
    let message: InterviewMessage

    private var isUser: Bool { message.role == .user }

    var body: some View {
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
        .padding(.horizontal, 16)
        .frame(maxWidth: .infinity, alignment: isUser ? .trailing : .leading)
    }
}

// MARK: - Typing Indicator

private struct TypingIndicator: View {
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

private struct InlineError: View {
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
