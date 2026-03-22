//
//  ForgotPasswordScreen.swift
//  Stridewell
//
//  UI-only placeholder. The forgot-password endpoint is not yet implemented
//  on the backend. The button is present but performs no action for now.
//

import SwiftUI

struct ForgotPasswordScreen: View {

    @State private var email: String = ""
    @FocusState private var isFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text("Forgot Password?")
                    .font(.title)
                    .fontWeight(.semibold)

                Text("We'll send you a link to reset it.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }
            .padding(.top, Spacing.xs)

            IconTextField(hint: "Email Address", symbol: "envelope", value: $email)
                .padding(.top, Spacing.xs)

            PrimaryButton(
                title: "Send Reset Link",
                isEnabled: !email.trimmingCharacters(in: .whitespaces).isEmpty, size: .large, action: { /* TODO: POST /auth/forgot-password */ }
            )
        }
        .padding(.horizontal, Spacing.lg)
        .padding(.top, Spacing.lg)
        .focused($isFocused)
        .ignoresSafeArea(.keyboard, edges: .bottom)
    }
}
