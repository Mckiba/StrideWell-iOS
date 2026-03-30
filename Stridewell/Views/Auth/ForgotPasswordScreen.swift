//
//  ForgotPasswordScreen.swift
//  Stridewell
//

import SwiftUI

struct ForgotPasswordScreen: View {

    @Environment(\.apiClient) private var apiClient

    @State private var email: String = ""
    @State private var isLoading = false
    @State private var errorMessage: String? = nil
    @State private var didSend = false

    // MARK: - Body

    var body: some View {
        VStack(spacing: Spacing.lg) {
            Spacer()

            if didSend {
                sentConfirmation
            } else {
                requestForm
            }

            Spacer()
        }
        .padding(.horizontal, Spacing.lg)
        .navigationTitle("Forgot Password")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Request Form

    private var requestForm: some View {
        VStack(spacing: Spacing.md) {
            VStack(spacing: Spacing.xs) {
                Image(systemName: "lock.rotation")
                    .font(.system(size: 44))
                    .foregroundStyle(.secondary)

                Text("Reset your password")
                    .font(.title3.bold())

                Text("Enter your email and we'll send you a link to reset your password.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            IconTextField(hint: "Email Address", symbol: "envelope", value: $email)
                .padding(.top, Spacing.xs)

            if let message = errorMessage {
                HStack(spacing: Spacing.xs) {
                    Image(systemName: "exclamationmark.triangle.fill")
                    Text(message)
                        .font(.callout)
                }
                .foregroundStyle(AppColor.destructive)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(Spacing.sm)
                .background(AppColor.destructive.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: CornerRadius.md))
            }

            PrimaryButton(
                title: "Send Reset Link",
                isEnabled: canSubmit,
                isLoading: isLoading,
                size: .large,
                action: { Task { await sendReset() } }
            )
        }
    }

    // MARK: - Sent Confirmation

    private var sentConfirmation: some View {
        VStack(spacing: Spacing.md) {
            Image(systemName: "envelope.badge.checkmark")
                .font(.system(size: 48))
                .foregroundStyle(AppColor.accent)

            VStack(spacing: Spacing.xs) {
                Text("Check your email")
                    .font(.title3.bold())

                Text("If **\(email)** has an account, you'll receive a password reset link shortly.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
    }

    // MARK: - Validation

    private var canSubmit: Bool {
        !email.trimmingCharacters(in: .whitespaces).isEmpty
    }

    // MARK: - Action

    private func sendReset() async {
        isLoading = true
        errorMessage = nil

        let result = await apiClient.forgotPassword(
            email: email.trimmingCharacters(in: .whitespaces)
        )

        switch result {
        case .success:
            didSend = true
        case .failure(_, let message):
            errorMessage = message
        }

        isLoading = false
    }
}
