//
//  ChatBubbleView.swift
//  Stridewell
//

import SwiftUI

struct ChatBubbleView: View {

    let content: String
    let isUser: Bool
    var subtitle: String? = nil

    var body: some View {
        VStack(alignment: isUser ? .trailing : .leading, spacing: 2) {
            HStack(alignment: .bottom, spacing: 0) {
                if isUser { Spacer(minLength: 56) }

                Text(content)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(isUser ? AppColor.accent : AppColor.surfaceElevated)
                    .foregroundStyle(isUser ? Color.white : AppColor.textPrimary)
                    .clipShape(RoundedRectangle(cornerRadius: CornerRadius.bubble))
                    .textSelection(.enabled)

                if !isUser { Spacer(minLength: 56) }
            }

            if let subtitle {
                Text(subtitle)
                    .font(.cardCaption)
                    .foregroundStyle(.tertiary)
                    .padding(.leading, 4)
            }
        }
        .padding(.horizontal, Spacing.md)
        .frame(maxWidth: .infinity, alignment: isUser ? .trailing : .leading)
    }
}

// MARK: - Previews

#Preview("User") {
    ChatBubbleView(content: "How's my training going?", isUser: true)
}

#Preview("Assistant") {
    ChatBubbleView(content: "You're making great progress this week!", isUser: false, subtitle: "coach")
}
