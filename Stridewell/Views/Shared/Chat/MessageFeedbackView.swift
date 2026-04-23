//
//  MessageFeedbackView.swift
//  Stridewell
//
//  V2 Phase 3 (M3.7): Thumbs up/down affordance shown beneath each assistant
//  chat bubble. On thumbs-down, an inline comment field slides in; it submits
//  on return or after 10s idle. Parent handles the actual PUT via closures.
//

import SwiftUI

struct MessageFeedbackView: View {

    // MARK: - Inputs

    /// Current feedback state on the message (nil = never voted).
    let feedback: MessageFeedback?

    /// Fired on tap of either thumb. `comment` is always nil here — the inline
    /// comment field uses `onCommentSubmit` for the thumbs-down flow.
    let onVote: (FeedbackVote) -> Void

    /// Fired when the user submits (or idle-auto-submits) the thumbs-down comment.
    /// Parent should call sendMessageFeedback(vote: .down, comment:).
    let onCommentSubmit: (String) -> Void

    // MARK: - Local state

    @State private var commentText: String = ""
    @State private var showCommentField: Bool = false
    @FocusState private var fieldFocused: Bool
    @State private var idleTask: Task<Void, Never>? = nil

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            HStack(spacing: Spacing.md) {
                thumbButton(
                    symbol: feedback?.vote == .up ? "hand.thumbsup.fill" : "hand.thumbsup",
                    active: feedback?.vote == .up,
                    action: {
                        // Switching to up hides the comment field.
                        dismissCommentField()
                        onVote(.up)
                    }
                )
                thumbButton(
                    symbol: feedback?.vote == .down ? "hand.thumbsdown.fill" : "hand.thumbsdown",
                    active: feedback?.vote == .down,
                    action: {
                        if feedback?.vote == .down {
                            // Tapping again while already down → toggle the comment field.
                            if showCommentField {
                                dismissCommentField()
                            } else {
                                showCommentField = true
                            }
                        } else {
                            onVote(.down)
                            showCommentField = true
                        }
                    }
                )
            }
            .padding(.leading, 4)

            if showCommentField && feedback?.vote == .down {
                commentField
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(.horizontal, Spacing.md)
        .animation(.easeInOut(duration: 0.2), value: showCommentField)
        .animation(.easeInOut(duration: 0.2), value: feedback?.vote)
    }

    // MARK: - Subviews

    @ViewBuilder
    private func thumbButton(symbol: String, active: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: 14))
                .foregroundStyle(active ? AppColor.accent : AppColor.textTertiary)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private var commentField: some View {
        HStack(spacing: Spacing.sm) {
            TextField("What went wrong? (optional)", text: $commentText)
                .font(.cardCaption)
                .textFieldStyle(.plain)
                .focused($fieldFocused)
                .submitLabel(.send)
                .onSubmit(submitComment)
                .onChange(of: commentText) { _, _ in
                    scheduleIdleSubmit()
                }

            Button(action: dismissCommentField) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 16))
                    .foregroundStyle(AppColor.textTertiary)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Close comment field")
        }
        .padding(.horizontal, Spacing.sm)
        .padding(.vertical, 6)
        .background(AppColor.surfaceElevated)
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.sm))
        .onAppear {
            // Auto-focus so the keyboard comes up immediately.
            fieldFocused = true
        }
        .onChange(of: fieldFocused) { _, isFocused in
            // Keyboard dismissed (tap outside, swipe-to-dismiss, etc.) →
            // submit whatever's in the field and close.
            if !isFocused && showCommentField {
                submitComment()
            }
        }
        .onDisappear {
            idleTask?.cancel()
        }
    }

    // MARK: - Behavior

    /// Submits the current text (if any) and hides the field. Called on return
    /// key, idle timeout, and keyboard dismissal.
    private func submitComment() {
        idleTask?.cancel()
        let trimmed = commentText.trimmingCharacters(in: .whitespacesAndNewlines)
        commentText = ""
        showCommentField = false
        fieldFocused = false
        guard !trimmed.isEmpty else { return }
        onCommentSubmit(trimmed)
    }

    /// Explicit close via X button — discards any draft text without sending.
    private func dismissCommentField() {
        idleTask?.cancel()
        commentText = ""
        showCommentField = false
        fieldFocused = false
    }

    /// Restart the 10s idle timer on every keystroke. Submits whatever is in
    /// the field when it fires (caps at 300 chars by backend validation).
    private func scheduleIdleSubmit() {
        idleTask?.cancel()
        idleTask = Task { @MainActor in
            try? await Task.sleep(for: .seconds(10))
            if Task.isCancelled { return }
            submitComment()
        }
    }
}

// MARK: - Previews

#Preview("Unvoted") {
    MessageFeedbackView(feedback: nil, onVote: { _ in }, onCommentSubmit: { _ in })
        .padding()
}

#Preview("Thumbs up") {
    MessageFeedbackView(
        feedback: MessageFeedback(vote: .up, comment: nil),
        onVote: { _ in },
        onCommentSubmit: { _ in }
    )
    .padding()
}

#Preview("Thumbs down — comment field") {
    MessageFeedbackView(
        feedback: MessageFeedback(vote: .down, comment: nil),
        onVote: { _ in },
        onCommentSubmit: { _ in }
    )
    .padding()
}
