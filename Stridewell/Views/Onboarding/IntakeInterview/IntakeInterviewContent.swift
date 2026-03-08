//
//  IntakeInterviewContent.swift
//  Stridewell
//

import SwiftUI

struct IntakeInterviewContent: View {

    let messages: [InterviewMessage]
    let screenState: ScreenState
    @Binding var inputText: String
    let canSend: Bool
    var onSend: () -> Void = {}
    var onRetry: () -> Void = {}

    enum ScreenState: Equatable {
        case loading
        case active
        case waiting
        case transitioning
        case error(String)

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
    }

    // MARK: - Message Thread

    private var messageThread: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 12) {
                    ForEach(messages) { msg in
                        ChatBubbleView(content: msg.content, isUser: msg.role == .user)
                    }

                    if screenState == .waiting || screenState == .loading {
                        HStack {
                            TypingIndicatorView()
                                .padding(.leading, 16)
                            Spacer()
                        }
                        .id("typing")
                    }

                    if case .error(let errorMsg) = screenState {
                        InlineErrorView(message: errorMsg, onRetry: onRetry)
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

            Button(action: onSend) {
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
}

// MARK: - Previews

private let mockMessages: [InterviewMessage] = [
    InterviewMessage(id: "1", role: .assistant, content: "Welcome! Let's build your training plan. What's your primary running goal right now?", agent_used: nil, created_at: "2026-03-07T10:00:00Z"),
    InterviewMessage(id: "2", role: .user, content: "I want to run a half marathon in under 2 hours.", agent_used: nil, created_at: "2026-03-07T10:01:00Z"),
    InterviewMessage(id: "3", role: .assistant, content: "Great goal! How many days per week are you currently running?", agent_used: nil, created_at: "2026-03-07T10:01:30Z"),
]

#Preview("Loading") {
    NavigationStack {
        IntakeInterviewContent(
            messages: [],
            screenState: .loading,
            inputText: .constant(""),
            canSend: false
        )
        .navigationTitle("Intake Interview")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview("Active") {
    NavigationStack {
        IntakeInterviewContent(
            messages: mockMessages,
            screenState: .active,
            inputText: .constant("About 3-4 days"),
            canSend: true
        )
        .navigationTitle("Intake Interview")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview("Waiting") {
    NavigationStack {
        IntakeInterviewContent(
            messages: mockMessages + [
                InterviewMessage(id: "4", role: .user, content: "About 3-4 days a week", agent_used: nil, created_at: "2026-03-07T10:02:00Z")
            ],
            screenState: .waiting,
            inputText: .constant(""),
            canSend: false
        )
        .navigationTitle("Intake Interview")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview("Error") {
    NavigationStack {
        IntakeInterviewContent(
            messages: mockMessages,
            screenState: .error("Network error. Please check your connection."),
            inputText: .constant(""),
            canSend: false
        )
        .navigationTitle("Intake Interview")
        .navigationBarTitleDisplayMode(.inline)
    }
}
