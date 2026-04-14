//
//  ResetPasswordScreen.swift
//  Stridewell
//
//  Presented as a fullScreenCover when the app opens via a Supabase
//  password-reset deep link (stridewell://auth/callback#access_token=...&type=recovery).
//

import SwiftUI

struct ResetPasswordScreen: View {

    let recovery: PendingReset

    @Environment(\.authStore) private var authStore
    @Environment(\.apiClient) private var apiClient
    @Environment(\.onboardingStore) private var onboardingStore
    @Environment(\.dismiss) private var dismiss

    @State private var password: String = ""
    @State private var confirmPassword: String = ""
    @State private var isLoading = false
    @State private var errorMessage: String? = nil

    // MARK: - Body

    var body: some View {
        NavigationStack {
            VStack(spacing: Spacing.lg) {
                Spacer()
                formContent
                Spacer()
            }
            .padding(.horizontal, Spacing.lg)
            .navigationTitle("Set New Password")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    // MARK: - Form

    private var formContent: some View {
        VStack(spacing: Spacing.md) {
            VStack(spacing: Spacing.xs) {
                Image(systemName: "lock.shield")
                    .font(.system(size: 44))
                    .foregroundStyle(AppColor.accent)

                Text("Choose a new password")
                    .font(.title3.bold())

                Text("Your new password must be at least 8 characters.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            VStack(spacing: Spacing.sm) {
                IconTextField(
                    hint: "New Password",
                    symbol: "lock",
                    isPassword: true,
                    value: $password
                )
                IconTextField(
                    hint: "Confirm Password",
                    symbol: "lock",
                    isPassword: true,
                    value: $confirmPassword
                )
            }
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
                title: "Update Password",
                isEnabled: canSubmit,
                isLoading: isLoading,
                size: .large,
                action: { Task { await submitReset() } }
            )
        }
    }

    // MARK: - Validation

    private var canSubmit: Bool {
        password.count >= 8 && !confirmPassword.isEmpty
    }

    // MARK: - Action

    private func submitReset() async {
        guard password == confirmPassword else {
            errorMessage = "Passwords do not match."
            return
        }

        isLoading = true
        errorMessage = nil

        let result = await apiClient.resetPassword(
            newPassword: password,
            recoveryToken: recovery.accessToken
        )

        switch result {
        case .success(let response):
            // Sign the user in immediately — no need to return to the login screen.
            authStore.signIn(token: response.token, userId: response.user_id)
            if case .success(let me) = await apiClient.me() {
                if me.onboarding_status == .complete || me.onboarding_status == .skipped {
                    onboardingStore.markComplete()
                }
            }
            dismiss()

        case .failure(_, let message):
            errorMessage = message
        }

        isLoading = false
    }
}
