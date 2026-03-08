//
//  InlineErrorView.swift
//  Stridewell
//

import SwiftUI

struct InlineErrorView: View {

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
        .padding(.vertical, Spacing.sm)
    }
}

#Preview {
    InlineErrorView(message: "Something went wrong") {}
        .padding()
}
