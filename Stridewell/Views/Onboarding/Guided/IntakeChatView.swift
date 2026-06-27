//
//  IntakeChatView.swift
//  Stridewell
//
//  The chat thread and input bar for an onboarding screen, rendered from an
//  IntakeChatModel.
//

import SwiftUI

struct IntakeChatView: View {

    let model: IntakeChatModel
    @State private var inputText = ""

    private var canSend: Bool {
        model.canSend && !inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        VStack(spacing: 0) {
            thread
            if model.phase != .transitioning {
                Divider()
                inputBar
            }
        }
    }

    // MARK: - Thread

    private var thread: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: Spacing.md) {
                    ForEach(model.messages) { msg in
                        ChatBubbleView(content: msg.content, isUser: msg.role == .user)
                    }

                    if model.phase == .waiting || model.phase == .loading {
                        HStack {
                            TypingIndicatorView().padding(.leading, Spacing.md)
                            Spacer()
                        }
                        .id("typing")
                    }

                    if case .error(let message) = model.phase {
                        InlineErrorView(message: message, onRetry: { Task { await model.retry() } })
                            .padding(.horizontal, Spacing.md)
                            .id("error")
                    }

                    Color.clear.frame(height: Spacing.sm).id("bottom")
                }
                .padding(.vertical, Spacing.md)
            }
            .scrollDismissesKeyboard(.interactively)
            .onChange(of: model.messages.count) {
                withAnimation(.easeOut(duration: 0.2)) { proxy.scrollTo("bottom") }
            }
            .onChange(of: model.phase) {
                switch model.phase {
                case .waiting, .loading:
                    withAnimation(.easeOut(duration: 0.2)) { proxy.scrollTo("typing") }
                case .error:
                    withAnimation(.easeOut(duration: 0.2)) { proxy.scrollTo("error") }
                default:
                    break
                }
            }
        }
    }

    // MARK: - Input bar

    private var inputBar: some View {
        HStack(alignment: .bottom, spacing: Spacing.sm) {
            TextField("Message…", text: $inputText, axis: .vertical)
                .padding(.horizontal, Spacing.sm)
                .padding(.vertical, Spacing.sm)
                .background(AppColor.surfaceElevated)
                .clipShape(RoundedRectangle(cornerRadius: CornerRadius.input))
                .lineLimit(1...5)
                .disabled(model.phase == .loading || model.phase == .waiting)

            Button {
                let text = inputText
                inputText = ""
                Task { await model.send(text) }
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
}
